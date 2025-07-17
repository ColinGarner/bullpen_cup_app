class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.references :tournament, null: false, foreign_key: true
      t.references :captain, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :teams, [:tournament_id, :name], unique: true
  end
end
