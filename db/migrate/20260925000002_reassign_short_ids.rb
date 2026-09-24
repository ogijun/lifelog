# subjects / events の主キーを UUID v4 (36 文字) から base58 11 文字に振り直す。
# events.subject_id と events.caused_by も同じ対応表で書き換える。
# 採番はアプリの ShortId を使わずここに書く (アプリ側が変わっても migration の意味を変えないため)。
# 対応表は残さないので戻せない。既に短い ID の行は触らない。
class ReassignShortIds < ActiveRecord::Migration[8.1]
  UUID_LENGTH = 36

  def up
    # 書き換えの途中は参照が一時的に切れる。FK の検査をコミット時まで遅らせる。
    execute "PRAGMA defer_foreign_keys = ON"

    reassign "subjects", references: [ %w[events subject_id] ]
    reassign "events", references: [ %w[events caused_by] ]
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "元の UUID との対応表は残していない"
  end

  private

  def reassign(table, references:)
    old_ids = select_values("SELECT id FROM #{table} WHERE length(id) = #{UUID_LENGTH}")
    return if old_ids.empty?

    taken = select_values("SELECT id FROM #{table}").to_set
    mapping = old_ids.index_with { fresh_id(taken) }

    execute "CREATE TEMP TABLE id_map (old TEXT PRIMARY KEY, new TEXT NOT NULL UNIQUE)"
    mapping.each_slice(500) do |slice|
      execute "INSERT INTO id_map (old, new) VALUES #{slice.map { |o, n| "(#{quote(o)}, #{quote(n)})" }.join(', ')}"
    end

    [ [ table, "id" ], *references ].each do |t, column|
      execute <<~SQL
        UPDATE #{t} SET #{column} = (SELECT new FROM id_map WHERE old = #{t}.#{column})
        WHERE #{column} IN (SELECT old FROM id_map)
      SQL
    end
  ensure
    execute "DROP TABLE IF EXISTS temp.id_map"
  end

  def fresh_id(taken)
    loop do
      id = SecureRandom.base58(11)
      return id if taken.add?(id)
    end
  end
end
