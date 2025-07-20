class AddInviteCodeToGroups < ActiveRecord::Migration[8.0]
  def up
    add_column :groups, :invite_code, :string, limit: 8
    add_index :groups, :invite_code, unique: true

    # Generate unique codes for existing groups
    Group.find_each do |group|
      group.update_column(:invite_code, generate_unique_code)
    end

    # Make the column required after populating existing records
    change_column_null :groups, :invite_code, false
  end

  def down
    remove_index :groups, :invite_code
    remove_column :groups, :invite_code
  end

  private

  def generate_unique_code
    loop do
      code = SecureRandom.alphanumeric(6).upcase
      break code unless Group.exists?(invite_code: code)
    end
  end
end
