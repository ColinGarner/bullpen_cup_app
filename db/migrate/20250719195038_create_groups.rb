class CreateGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.jsonb :settings, default: {}
      t.string :contact_email
      t.string :contact_phone
      t.text :address

      t.timestamps
    end
    add_index :groups, :slug, unique: true
    add_index :groups, :active
    add_index :groups, :name
  end
end
