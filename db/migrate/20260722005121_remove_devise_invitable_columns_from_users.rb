class RemoveDeviseInvitableColumnsFromUsers < ActiveRecord::Migration[8.0]
  # devise_invitable columns were added but the gem is not in the Gemfile
  # and nothing references these fields.
  def up
    remove_index :users, name: "index_users_on_invitation_token", if_exists: true
    remove_index :users, name: "index_users_on_invited_by_id",    if_exists: true
    remove_index :users, name: "index_users_on_invited_by",       if_exists: true

    remove_column :users, :invitation_token
    remove_column :users, :invitation_created_at
    remove_column :users, :invitation_sent_at
    remove_column :users, :invitation_accepted_at
    remove_column :users, :invitation_limit
    remove_column :users, :invited_by_type
    remove_column :users, :invited_by_id
    remove_column :users, :invitations_count
  end

  def down
    add_column :users, :invitation_token,        :string
    add_column :users, :invitation_created_at,   :datetime
    add_column :users, :invitation_sent_at,      :datetime
    add_column :users, :invitation_accepted_at,  :datetime
    add_column :users, :invitation_limit,        :integer
    add_column :users, :invited_by_type,         :string
    add_column :users, :invited_by_id,           :bigint
    add_column :users, :invitations_count,       :integer, default: 0

    add_index :users, :invitation_token, unique: true, name: "index_users_on_invitation_token"
    add_index :users, :invited_by_id,                  name: "index_users_on_invited_by_id"
    add_index :users, [ :invited_by_type, :invited_by_id ], name: "index_users_on_invited_by"
  end
end
