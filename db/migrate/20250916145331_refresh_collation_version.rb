class RefreshCollationVersion < ActiveRecord::Migration[8.0]
  def up
    # Fix collation version mismatch that occurs when PostgreSQL is updated
    # but template databases still have old collation versions
    
    begin
      # Refresh collation version for template1 database
      execute "ALTER DATABASE template1 REFRESH COLLATION VERSION"
      puts "✅ Refreshed collation version for template1"
    rescue ActiveRecord::StatementInvalid => e
      puts "⚠️  Could not refresh template1 collation (this may be expected): #{e.message}"
    end

    begin
      # Refresh collation version for postgres database  
      execute "ALTER DATABASE postgres REFRESH COLLATION VERSION"
      puts "✅ Refreshed collation version for postgres database"
    rescue ActiveRecord::StatementInvalid => e
      puts "⚠️  Could not refresh postgres collation (this may be expected): #{e.message}"
    end

    begin
      # Refresh collation version for current database if it's not one of the above
      current_db = connection.current_database
      unless ['template1', 'postgres'].include?(current_db)
        execute "ALTER DATABASE #{current_db} REFRESH COLLATION VERSION"
        puts "✅ Refreshed collation version for #{current_db}"
      end
    rescue ActiveRecord::StatementInvalid => e
      puts "⚠️  Could not refresh #{current_db} collation: #{e.message}"
    end
  end

  def down
    # This migration cannot be reversed as it's fixing a system-level issue
    puts "This migration cannot be reversed - collation versions remain refreshed"
  end
end
