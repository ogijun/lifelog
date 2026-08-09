class CreateCurrentStateView < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE VIEW current_state AS
      SELECT s.*, e.type AS status, e.occurred_on AS as_of
      FROM subjects s
      JOIN events e ON e.id = (
        SELECT id FROM events WHERE subject_id = s.id
        ORDER BY occurred_on DESC, id DESC LIMIT 1
      )
    SQL
  end

  def down
    execute "DROP VIEW current_state"
  end
end
