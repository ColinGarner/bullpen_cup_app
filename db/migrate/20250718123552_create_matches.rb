class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.references :round, null: false, foreign_key: true
      t.references :team_a, null: false, foreign_key: { to_table: :teams }
      t.references :team_b, null: false, foreign_key: { to_table: :teams }
      t.string :match_type, null: false
      t.string :status, null: false, default: 'upcoming'
      t.references :winner_team, null: true, foreign_key: { to_table: :teams }
      t.datetime :scheduled_time
      t.datetime :completed_at

      t.timestamps
    end
    
    # Add indexes for performance
    add_index :matches, :match_type
    add_index :matches, :status
    add_index :matches, [:round_id, :status]
    add_index :matches, [:team_a_id, :team_b_id]
    
    # Add constraint to ensure teams are different
    add_check_constraint :matches, "team_a_id != team_b_id", name: "matches_different_teams"
  end
end
