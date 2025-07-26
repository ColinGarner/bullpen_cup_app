class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      t.string :name, null: false
      t.string :club_name, null: false
      t.text :address
      t.string :city
      t.string :state
      t.string :country, default: 'United States'
      t.string :api_course_id # For courses from external API

      t.timestamps
    end

    # Indexes for performance and uniqueness
    add_index :courses, :api_course_id, unique: true, where: "api_course_id IS NOT NULL"
    add_index :courses, [:name, :city, :state]
    add_index :courses, :club_name
  end
end
