class AddGolfCourseFieldsToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :golf_course_id, :string
    add_column :matches, :golf_course_name, :string
    add_column :matches, :golf_course_location, :string
    
    add_index :matches, :golf_course_id
  end
end
