class CreateGroupMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: 'member'
      t.datetime :joined_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :group_memberships, [ :group_id, :user_id ], unique: true
    add_index :group_memberships, :role
    add_index :group_memberships, :joined_at
  end
end
