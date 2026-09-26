# lifelog

本・映画・料理・店 (外食)・動画を同一のデータモデルで記録する個人用ライフログ。
Rails 8.1 / Hotwire (importmap) / SQLite。

**設計判断とその理由はすべて [DESIGN.md](DESIGN.md) にある。実装を変える前に読むこと。**

## このリポジトリ固有の規約

- **削減の優先順位は 状態 > 結合 > 複雑性 > コード量。** 対立したらこの順で決める。
- **`app/controllers/{books,films,dishes,places,videos}_controller.rb` と対応するフォームは意図的な重複。**
  「共通化できる」と見えるが、統一フォームは「今どの種類か」という状態を持つ。**統合しない。**
  5つ全部に同じ変更を入れるのが正しい対応。
- **`events.type` は追記のみ。** モデルで拒否している。
  状態を変えたいときは UPDATE ではなくイベントを追記する。`occurred_on` / `rating` / `note` / `title` は普通に UPDATE してよい。
- **`events.occurred_on` は精度可変の文字列** (`"2026"` / `"2026-03"` / `"2026-03-05"` / `NULL` = 不明)。
  Date として扱わず `FuzzyDate` を通す。同じ日付どうしは `created_at` で並べる (`id` はランダム)。
- **現在の状態は `current_state` ビューから読む。** `events` を直接畳んで status を計算しない。
- **`events.type` は STI の予約カラム名だが `inheritance_column = nil` で無効化済み。** リネームしない。
- **`schema_format = :sql`。** ビューを保持するため。migration 後は `db/structure.sql` をコミットする。

## コマンド

```sh
bin/rails test      # 174件, 1秒未満
bin/rubocop
bin/rails db:reset  # 再作成 + seed (連鎖の実例が入る)
bin/rails server
```

## 注意

- **public リポジトリ。** 運用で溜まった実データを seed / fixture / テストに入れないこと。
- 外部 API 連携は未実装。入れるときは `subjects.external_ids` (JSON) に格納する。
- **外部から画像を取るのは `RemoteImage` だけ。** SSRF 対策 (内部アドレスの拒否、解決した IP への直接接続、
  リダイレクトを追わない、上限) が入っている。別の経路で `Net::HTTP` や `open-uri` を使わない。
- 画像 (`Subject#cover`) は Active Storage の抽象だけを使う。ローカルのファイルパスに依存しない (保存先を後で変えるため)。
