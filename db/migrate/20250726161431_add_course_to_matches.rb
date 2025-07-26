class AddCourseToMatches < ActiveRecord::Migration[8.0]
  def change
    add_reference :matches, :course, null: true, foreign_key: true
  end
end
