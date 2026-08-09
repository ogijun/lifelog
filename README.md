# lifelog

本・映画・料理・場所を同一のデータモデルで記録し、体験どうしの相互参照を辿る個人用ライフログ。

設計とその理由は [DESIGN.md](DESIGN.md)。

## 動かす

```sh
bin/setup            # bundle install + db:prepare
bin/rails db:seed    # 連鎖の実例が入る (任意)
bin/rails server
```

## 構成

| 場所 | 役割 |
| --- | --- |
| `db/migrate/` | `subjects` / `events` の2テーブルと `current_state` ビュー |
| `app/models/subject.rb` `event.rb` | 記録の対象と、追記のみの遷移イベント |
| `app/models/current_state.rb` | ビューの読み取り専用モデル。「最新イベントが現在の状態」 |
| `app/models/recorder.rb` `timeline.rb` `wishlist.rb` | 状態を持たないクエリ層 |
| `app/controllers/{books,films,dishes,places}_controller.rb` | 種類ごとの入力。**意図的なコピー**、統合しない |

## テスト

```sh
bin/rails test
bin/rubocop
```
