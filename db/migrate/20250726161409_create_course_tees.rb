class CreateCourseTees < ActiveRecord::Migration[8.0]
  def change
    create_table :course_tees do |t|
      t.references :course, null: false, foreign_key: true
      t.string :tee_name, null: false
      t.string :gender, null: false
      t.decimal :course_rating, precision: 4, scale: 1, null: false
      t.integer :slope_rating, null: false
      t.integer :total_yards, null: false
      t.integer :total_meters, null: false
      t.integer :par_total, null: false

      t.timestamps
    end

    # Unique constraint: each tee name must be unique per course and gender
    add_index :course_tees, [:course_id, :tee_name, :gender], unique: true
    add_index :course_tees, :gender
  end
end
