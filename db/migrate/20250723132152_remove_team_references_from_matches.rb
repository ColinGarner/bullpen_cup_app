class RemoveTeamReferencesFromMatches < ActiveRecord::Migration[8.0]
  def change
    # Remove the check constraint first
    remove_check_constraint :matches, name: "matches_different_teams"

    # Remove the compound index
    remove_index :matches, [ :team_a_id, :team_b_id ]

    # Remove the foreign key constraints and columns
    remove_reference :matches, :team_a, foreign_key: { to_table: :teams }
    remove_reference :matches, :team_b, foreign_key: { to_table: :teams }
  end
end
