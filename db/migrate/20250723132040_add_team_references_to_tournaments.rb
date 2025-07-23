class AddTeamReferencesToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_reference :tournaments, :team_a, null: true, foreign_key: { to_table: :teams }
    add_reference :tournaments, :team_b, null: true, foreign_key: { to_table: :teams }

    # Add constraint to ensure teams are different
    add_check_constraint :tournaments, "team_a_id != team_b_id", name: "tournaments_different_teams"
  end
end
