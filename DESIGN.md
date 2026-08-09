# lifelog 設計

本・映画・料理・場所を**同一のデータモデル**で記録し、体験どうしの相互参照を辿れるようにする個人用ライフログ。

小説を読む → 映画化を観る → 舞台の街に行く → そこで食べたものを再現する、という連鎖が一本の線として辿れることが目的。

## 設計指針

削減の優先順位は **状態 > 結合 > 複雑性 > コード量**。

- 状態を減らせるなら結合を増やしてよい
- 結合を減らせるなら複雑にしてよい
- 複雑さが減るならコードをコピーしてよい
- 重複排除は上3つを悪化させない時だけ

純粋なイベントソーシングにはしない。スナップショット・リプレイ基盤は個人用途に対して過剰なので、
「遷移だけ追記のみ、属性は素直に UPDATE」という折衷を採る。

## 技術選定

| 選択 | 理由 |
| --- | --- |
| SQLite | 単一ファイル、ローカルファースト、10年動かす前提。バックアップが `cp` 一発 |
| Rails 8 | 1人で10年運用するなら、フレームワークが標準で寿命を持っていることが最大の価値。ActiveRecord の migration が「スキーマの穴を運用しながら潰す」フェーズに直接効く |
| Hotwire (Turbo + Stimulus) | **クライアント状態を持たないため。** 指針の第一項に直結する。ビルド工程も node_modules も無く、10年後も `bin/rails s` だけで起動できる |
| importmap | 同上。JS のビルド成果物という「状態」を持たない |

SPA を採らないのは、フォームの入力途中・一覧のフィルタ・選択中の kind といったものが
すべてクライアント側の可変状態になるため。サーバがレンダリングした HTML を差し替えるだけなら、
真実は常に DB に一つだけある。

## データモデル

2テーブル + 1ビュー。テーブル名は Rails 規約に合わせ複数形 (`subjects` / `events`) にしているが、
構造は handoff の DDL と同一。

```sql
CREATE TABLE subjects (
  id           TEXT PRIMARY KEY,   -- UUID v4
  kind         TEXT NOT NULL,      -- book / film / dish / place
  title        TEXT NOT NULL,
  creator      TEXT,               -- 著者・監督・店名など
  external_ids TEXT,               -- JSON: {"isbn": "...", "tmdb": "...", "google_place": "..."}
  lat          REAL,               -- 場所の検索に使うので JSON ではなく独立カラム
  lng          REAL,
  created_at   TEXT NOT NULL
);

CREATE TABLE events (
  id          TEXT PRIMARY KEY,
  subject_id  TEXT NOT NULL REFERENCES subjects(id),
  type        TEXT NOT NULL,       -- wished / did / dropped
  occurred_on TEXT NOT NULL,       -- ISO 8601 date
  rating      INTEGER,             -- 1-5, nullable
  note        TEXT,
  caused_by   TEXT REFERENCES events(id),  -- このイベントを引き起こしたイベント
  created_at  TEXT NOT NULL
);

CREATE VIEW current_state AS
SELECT s.*, e.type AS status, e.occurred_on AS as_of
FROM subjects s
JOIN events e ON e.id = (
  SELECT id FROM events WHERE subject_id = s.id
  ORDER BY occurred_on DESC, id DESC LIMIT 1
);
```

### 重要な設計判断とその理由

**`events` に status カラムを持たせない。**
現在の状態はイベント列の最新から導出する。これにより「読みたいと思ってから読むまでの期間」が
計算でき、再読・再訪も `did` が複数並ぶだけで特別扱いが不要になる。
アプリ側は基本的に `current_state` ビューを読むので、複雑性はビュー1箇所に閉じ込められる。

**追記のみを守るのは遷移イベントだけ。**
`type` と `occurred_on` は後から書き換えない (時系列上の意味が壊れるため)。モデルで readonly を強制する。
一方 `rating` `note` `title` は普通に UPDATE してよい。「星いくつだったか」は最新の判断だけあれば十分で、
訂正のたびに補正イベントを積むのは割に合わない。

**関係テーブルは作らない。**
`caused_by` の自己参照だけに留める。任意の関係種別 (inspired_by, adapted_from 等) を張れる別テーブルは
表現力が高いが結合が増える。必要になってから足す。

**`subjects.kind` は文字列、種類別テーブルは作らない。**
種類ごとに分けると横断クエリが破綻する。種類固有の属性は `external_ids` と同様に JSON へ逃がし、
マイグレーションを不要にする。

**`type` カラム名を維持する。**
Rails では `type` は STI 用の予約カラムだが、handoff の DDL に忠実であることを優先し、
`Event.inheritance_column = nil` で STI を無効化する。カラム名を変えると
DDL とアプリの語彙がずれ、10年後に読む自分が混乱する方が高くつく。

**ID は UUID v4 の文字列。**
handoff の DDL が TEXT PRIMARY KEY であること、および外部 API から取得したデータを
オフラインで生成・後からマージする余地を残すため。連番の採番は「次の値」という状態を DB に作る。

## 未決事項への回答

**`wished` が無限に溜まる問題** → wished 一覧のデフォルトソートを**日替わりシード付きランダム**にする。
`ORDER BY substr(hash, ...)` 相当を SQLite の関数で組み、その日のうちは同じ並びになるようにする。
これで「今日の候補」が毎日入れ替わり、かつリロードのたびに変わって落ち着かない、ということもない。
シードは日付から導出するので、**保存する状態はゼロ**。

**イベント型を kind ごとに分けるか** → 分けない。`wished` / `did` / `dropped` の3種のみ。
場所の「住んだ」のような区別は `note` に書く。kind ごとに許可型を変えると `kind` と `type` の間に
結合が生まれ、横断クエリと一覧ビューの両方に分岐が波及する。必要になってから足す。

**入力フォームは kind ごとに4つコピーして作る。**
統一フォームは「今どの種類か」というフォーム状態を持つ。コード量は増えるが、
状態が消え、1つのフォームを直しても他の3つが壊れない (結合も消える)。指針の適用そのもの。

## 実装の順序

1. スキーマ + マイグレーション (view 込み)
2. イベント追記と `current_state` 参照のクエリ層
3. kind ごとに分けた4つの入力フォーム
4. 時系列に全部並ぶだけの一覧ビュー

ビューの作り込みは後回し。データが正しく入っていれば後からいくらでも作れる。

## やらないこと

- 既存サービスからの過去データ移行 (2週間手で運用してスキーマの穴を潰してから)
- 認証・マルチユーザー
- SNS 機能
- `started` イベント型 (読みかけを扱いたくなってから足す)
- 外部 API 連携 (`external_ids` に入れる前提だけ整えておく)
