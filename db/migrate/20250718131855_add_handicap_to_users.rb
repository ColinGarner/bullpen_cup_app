class AddHandicapToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :handicap, :decimal, precision: 4, scale: 1
  end
end
