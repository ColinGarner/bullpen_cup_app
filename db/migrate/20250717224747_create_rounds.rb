class CreateRounds < ActiveRecord::Migration[8.0]
  def change
    create_table :rounds do |t|
      t.references :tournament, null: false, foreign_key: true
      t.integer :round_number, null: false
      t.string :name, null: false
      t.date :date
      t.string :status, null: false, default: 'upcoming'
      t.text :description

      t.timestamps
    end

    add_index :rounds, [ :tournament_id, :round_number ], unique: true
    add_index :rounds, [ :tournament_id, :date ]
    add_index :rounds, :status
  end
end
