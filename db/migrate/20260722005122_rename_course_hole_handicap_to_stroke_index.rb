class RenameCourseHoleHandicapToStrokeIndex < ActiveRecord::Migration[8.0]
  # `handicap` overloaded the term with users.handicap. The value here is a
  # hole's stroke index (1..18) — the ranking used to allocate strokes.
  # JSON payloads to/from the external golf API keep the key "handicap"
  # (that's their convention); only the column and Ruby-side identifiers change.
  def change
    # rename_column on Postgres also renames associated indexes in Rails 8+.
    rename_column :course_holes, :handicap, :stroke_index
  end
end
