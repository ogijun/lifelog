# occurred_on を精度可変・不明可の文字列にする ("2026" / "2026-03" / "2026-03-05" / NULL)。
# 既存の値は既に "YYYY-MM-DD" の文字列なので変換しない。
# SQLite の列変更はテーブルの作り直しになるので、参照しているビューを外してから戻す。
# ビューは同じ日付どうしを id (ランダムな UUID) ではなく記録順で並べるように直す。
class MakeOccurredOnFuzzy < ActiveRecord::Migration[8.1]
  def up
    execute "DROP VIEW current_state"
    change_column :events, :occurred_on, :string, null: true
    create_current_state_view(tiebreak: "created_at DESC, id DESC")
  end

  # 日の精度の日付しか無いときだけ戻せる。
  def down
    fuzzy = select_value(<<~SQL)
      SELECT COUNT(*) FROM events WHERE occurred_on IS NULL OR length(occurred_on) <> 10
    SQL
    raise ActiveRecord::IrreversibleMigration, "日の精度でない occurred_on が #{fuzzy} 件ある" if fuzzy.positive?

    execute "DROP VIEW current_state"
    change_column :events, :occurred_on, :date, null: false
    create_current_state_view(tiebreak: "id DESC")
  end

  private

  def create_current_state_view(tiebreak:)
    execute <<~SQL
      CREATE VIEW current_state AS
      SELECT s.*, e.type AS status, e.occurred_on AS as_of
      FROM subjects s
      JOIN events e ON e.id = (
        SELECT id FROM events WHERE subject_id = s.id
        ORDER BY occurred_on DESC, #{tiebreak} LIMIT 1
      )
    SQL
  end
end
