class CreateSubjectsAndEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :subjects, id: :string do |t|
      t.string :kind, null: false
      t.string :title, null: false
      t.string :creator
      t.text :external_ids
      t.float :lat
      t.float :lng
      t.datetime :created_at, null: false
    end
    add_index :subjects, :kind
    add_index :subjects, [ :lat, :lng ]

    create_table :events, id: :string do |t|
      t.references :subject, null: false, type: :string, foreign_key: true
      t.string :type, null: false
      t.date :occurred_on, null: false
      t.integer :rating
      t.text :note
      t.string :caused_by
      t.datetime :created_at, null: false
    end
    add_foreign_key :events, :events, column: :caused_by
    add_index :events, [ :subject_id, :occurred_on ]
    add_index :events, :occurred_on
  end
end
