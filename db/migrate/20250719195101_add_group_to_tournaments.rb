class AddGroupToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_reference :tournaments, :group, null: true, foreign_key: true
  end
end
