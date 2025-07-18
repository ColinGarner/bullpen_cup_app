class RefactorTournamentStatusToDates < ActiveRecord::Migration[8.0]
  def up
    # Add cancelled boolean field
    add_column :tournaments, :cancelled, :boolean, null: false, default: false
    add_index :tournaments, :cancelled

    # Migrate existing data
    # Any tournaments with status 'cancelled' should have cancelled = true
    execute "UPDATE tournaments SET cancelled = true WHERE status = 'cancelled'"

    # Remove the status column
    remove_index :tournaments, :status
    remove_column :tournaments, :status
  end

  def down
    # Add status column back
    add_column :tournaments, :status, :string, null: false, default: 'upcoming'
    add_index :tournaments, :status

    # Migrate data back (best effort)
    # Set cancelled tournaments back to 'cancelled' status
    execute "UPDATE tournaments SET status = 'cancelled' WHERE cancelled = true"

    # For non-cancelled tournaments, determine status based on dates
    execute <<-SQL
      UPDATE tournaments#{' '}
      SET status = CASE#{' '}
        WHEN start_date > CURRENT_DATE THEN 'upcoming'
        WHEN start_date <= CURRENT_DATE AND end_date >= CURRENT_DATE THEN 'active'
        WHEN end_date < CURRENT_DATE THEN 'completed'
        ELSE 'upcoming'
      END
      WHERE cancelled = false
    SQL

    # Remove cancelled column
    remove_index :tournaments, :cancelled
    remove_column :tournaments, :cancelled
  end
end
