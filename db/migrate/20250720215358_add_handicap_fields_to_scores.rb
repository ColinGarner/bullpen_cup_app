class AddHandicapFieldsToScores < ActiveRecord::Migration[8.0]
  def change
    # Add net score (calculated from gross - strokes received)
    add_column :scores, :net_strokes, :integer

    # Store the handicap that was used at the time of scoring (historical snapshot)
    add_column :scores, :handicap_used, :decimal, precision: 4, scale: 1

    # Store how many strokes the player received on this specific hole
    add_column :scores, :strokes_received_on_hole, :integer, default: 0, null: false

    # For match play: track hole-by-hole results ('won', 'lost', 'halved', 'pending')
    add_column :scores, :hole_result, :string

    # Add indexes for performance
    add_index :scores, [ :match_id, :hole_number ], name: "index_scores_on_match_and_hole"
    add_index :scores, [ :user_id, :handicap_used ], name: "index_scores_on_user_and_handicap"
    add_index :scores, :hole_result, name: "index_scores_on_hole_result"

    # Add a unique constraint to prevent duplicate scores for same user/match/hole
    add_index :scores, [ :match_id, :user_id, :hole_number ], unique: true, name: "index_scores_unique_per_hole"
  end
end
