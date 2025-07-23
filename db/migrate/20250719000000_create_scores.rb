class CreateScores < ActiveRecord::Migration[8.0]
  def change
    create_table :scores do |t|
      t.references :match, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :hole_number
      t.integer :strokes

      t.timestamps
    end

    # Add basic indexes for performance
    add_index :scores, [ :match_id, :user_id, :hole_number ], unique: true, name: "index_scores_unique_per_hole"
  end
end
