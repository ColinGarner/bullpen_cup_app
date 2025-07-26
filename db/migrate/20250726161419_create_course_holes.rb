class CreateCourseHoles < ActiveRecord::Migration[8.0]
  def change
    create_table :course_holes do |t|
      t.references :course_tee, null: false, foreign_key: true
      t.integer :hole_number, null: false
      t.integer :par, null: false
      t.integer :yardage, null: false
      t.integer :handicap, null: false

      t.timestamps
    end

    # Unique constraint: each hole number must be unique per tee
    add_index :course_holes, [:course_tee_id, :hole_number], unique: true
    add_index :course_holes, :hole_number
    add_index :course_holes, :handicap
  end
end
