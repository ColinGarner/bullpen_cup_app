class CreateMatchPlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :match_players do |t|
      t.references :match, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Add indexes for performance
    add_index :match_players, [ :match_id, :team_id ]
    add_index :match_players, [ :match_id, :user_id ]
    add_index :match_players, [ :team_id, :user_id ]

    # Ensure a player can't be in the same match multiple times
    add_index :match_players, [ :match_id, :user_id ], unique: true, name: "index_match_players_on_match_and_user_unique"
  end
end
