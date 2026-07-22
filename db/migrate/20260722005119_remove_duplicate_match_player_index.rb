class RemoveDuplicateMatchPlayerIndex < ActiveRecord::Migration[8.0]
  # The unique index `index_match_players_on_match_and_user_unique` already
  # covers `(match_id, user_id)`, so the non-unique companion is dead weight.
  def up
    remove_index :match_players, name: "index_match_players_on_match_id_and_user_id"
  end

  def down
    add_index :match_players, [ :match_id, :user_id ],
      name: "index_match_players_on_match_id_and_user_id"
  end
end
