# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting to seed the database..."

# Production-safe seeding - only create if not exists
# Do NOT destroy existing data in production!

# Create Admin User (only if one doesn't exist)
puts "👑 Ensuring admin user exists..."
admin = User.find_or_create_by(email: "admin@bullpencup.com") do |user|
  user.first_name = "Admin"
  user.last_name = "User"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.admin = true
end

if admin.persisted? && !admin.admin?
  admin.update!(admin: true)
end

puts "✅ Admin user ready: #{admin.display_name} (#{admin.email})"

# Only create sample data in development environment
if Rails.env.development?
  puts "🚀 Creating sample data for development environment..."
  
  # Clear existing data in development only
  puts "🧹 Cleaning up existing development data..."
  TeamMembership.where.not(user: admin).destroy_all
  Team.destroy_all
  Round.destroy_all
  Tournament.where.not(created_by: admin).destroy_all
  User.where.not(email: admin.email).destroy_all

  # Create sample users for development
  puts "👥 Creating sample users..."
  users_data = [
    { first_name: "Tiger", last_name: "Woods", email: "tiger.woods@bullpen.com" },
    { first_name: "Phil", last_name: "Mickelson", email: "phil.mickelson@bullpen.com" },
    { first_name: "Jordan", last_name: "Spieth", email: "jordan.spieth@bullpen.com" },
    { first_name: "Rory", last_name: "McIlroy", email: "rory.mcilroy@bullpen.com" },
    { first_name: "Brooks", last_name: "Koepka", email: "brooks.koepka@bullpen.com" },
    { first_name: "Dustin", last_name: "Johnson", email: "dustin.johnson@bullpen.com" },
    { first_name: "Jon", last_name: "Rahm", email: "jon.rahm@bullpen.com" },
    { first_name: "Justin", last_name: "Thomas", email: "justin.thomas@bullpen.com" },
    { first_name: "Collin", last_name: "Morikawa", email: "collin.morikawa@bullpen.com" },
    { first_name: "Bryson", last_name: "DeChambeau", email: "bryson.dechambeau@bullpen.com" },
    { first_name: "Patrick", last_name: "Cantlay", email: "patrick.cantlay@bullpen.com" },
    { first_name: "Xander", last_name: "Schauffele", email: "xander.schauffele@bullpen.com" },
    { first_name: "Tony", last_name: "Finau", email: "tony.finau@bullpen.com" },
    { first_name: "Viktor", last_name: "Hovland", email: "viktor.hovland@bullpen.com" },
    { first_name: "Cameron", last_name: "Smith", email: "cameron.smith@bullpen.com" }
  ]

  users = users_data.map do |user_data|
    User.create!(
      first_name: user_data[:first_name],
      last_name: user_data[:last_name],
      email: user_data[:email],
      password: "password123",
      password_confirmation: "password123",
      admin: false
    )
  end

  puts "✅ Created #{users.count} sample users"

  # Rest of sample data creation only for development...
  # (keeping the tournament, team, and round creation code but only for development)
  
  puts "🏆 Creating sample tournaments..."
  
  tournament1 = Tournament.create!(
    name: "Bullpen Cup 2024 Spring Championship",
    description: "The premier spring golf tournament featuring the best players from across the region. Four rounds of challenging golf across beautiful courses.",
    start_date: 2.weeks.from_now.to_date,
    end_date: (2.weeks.from_now + 3.days).to_date,
    status: "upcoming",
    venue: "Augusta Hills Golf Club",
    created_by: admin
  )

  tournament2 = Tournament.create!(
    name: "Summer Scramble Tournament",
    description: "A fun, relaxed tournament perfect for teams of all skill levels. Emphasis on teamwork and enjoying the game.",
    start_date: 1.month.from_now.to_date,
    end_date: (1.month.from_now + 2.days).to_date,
    status: "upcoming",
    venue: "Pebble Creek Country Club",
    created_by: users.first
  )

  tournament3 = Tournament.create!(
    name: "Winter Classic 2023",
    description: "Last year's winter tournament - completed with great success!",
    start_date: 2.months.ago.to_date,
    end_date: (2.months.ago + 3.days).to_date,
    status: "completed",
    venue: "Pine Valley Golf Course",
    created_by: admin
  )

  puts "✅ Created tournaments: #{Tournament.count} total"

  # Continue with teams and rounds creation...
  puts "⛳ Creating teams for tournaments..."

  # Create teams for Spring Championship (8 teams with 2 players each)
  teams_data = [
    { name: "Eagle Masters", captain: users[0], players: [users[0], users[1]] },
    { name: "Birdie Brigade", captain: users[2], players: [users[2], users[3]] },
    { name: "Par Excellence", captain: users[4], players: [users[4], users[5]] },
    { name: "Fairway Legends", captain: users[6], players: [users[6], users[7]] },
    { name: "Green Guardians", captain: users[8], players: [users[8], users[9]] },
    { name: "Tee Time Titans", captain: users[10], players: [users[10], users[11]] },
    { name: "Rough Riders", captain: users[12], players: [users[12], users[13]] },
    { name: "Sand Trap Heroes", captain: users[14], players: [users[14], admin] }
  ]

  teams_data.each do |team_data|
    team = Team.create!(
      name: team_data[:name],
      tournament: tournament1,
      captain: team_data[:captain]
    )
    
    # Add additional players (captain is automatically added by callback)
    team_data[:players].each do |player|
      unless player == team_data[:captain]
        team.add_player(player)
      end
    end
    
    puts "✅ Created team: #{team.name} with #{team.player_count} players (Captain: #{team.captain.display_name})"
  end

  # Create teams for Summer Scramble (4 teams with 3-4 players each)
  summer_teams = [
    { name: "Summer Sluggers", captain: users[1], players: [users[1], users[5], users[9]] },
    { name: "Heat Wave", captain: users[3], players: [users[3], users[7], users[11], users[13]] },
    { name: "Sunshine Squad", captain: users[2], players: [users[2], users[6], users[10]] },
    { name: "Hot Shots", captain: users[4], players: [users[4], users[8], users[12], admin] }
  ]

  summer_teams.each do |team_data|
    team = Team.create!(
      name: team_data[:name],
      tournament: tournament2,
      captain: team_data[:captain]
    )
    
    # Add additional players
    team_data[:players].each do |player|
      unless player == team_data[:captain]
        team.add_player(player)
      end
    end
    
    puts "✅ Created team: #{team.name} with #{team.player_count} players (Captain: #{team.captain.display_name})"
  end

  puts "🎯 Creating rounds for tournaments..."

  # Create rounds for Spring Championship
  round1 = Round.create!(
    tournament: tournament1,
    round_number: 1,
    name: "Opening Round",
    description: "First round to set the pace",
    date: tournament1.start_date,
    status: "upcoming"
  )

  round2 = Round.create!(
    tournament: tournament1,
    round_number: 2,
    name: "Challenge Round",
    description: "The most difficult course layout",
    date: tournament1.start_date + 1.day,
    status: "upcoming"
  )

  round3 = Round.create!(
    tournament: tournament1,
    round_number: 3,
    name: "Moving Day",
    description: "Where tournaments are won or lost",
    date: tournament1.start_date + 2.days,
    status: "upcoming"
  )

  round4 = Round.create!(
    tournament: tournament1,
    round_number: 4,
    name: "Championship Final",
    description: "The final round to determine the champion",
    date: tournament1.start_date + 3.days,
    status: "upcoming"
  )

  # Create rounds for Summer Scramble
  Round.create!(
    tournament: tournament2,
    round_number: 1,
    name: "Scramble Start",
    description: "Team scramble format - best ball",
    date: tournament2.start_date,
    status: "upcoming"
  )

  Round.create!(
    tournament: tournament2,
    round_number: 2,
    name: "Summer Finale",
    description: "Final round with prizes and celebration",
    date: tournament2.start_date + 2.days,
    status: "upcoming"
  )

  # Create completed rounds for Winter Classic
  Round.create!(
    tournament: tournament3,
    round_number: 1,
    name: "Winter Opener",
    description: "Braving the cold for great golf",
    date: tournament3.start_date,
    status: "completed"
  )

  Round.create!(
    tournament: tournament3,
    round_number: 2,
    name: "Frost Final",
    description: "Championship round in winter conditions",
    date: tournament3.start_date + 3.days,
    status: "completed"
  )

  puts "✅ Created rounds: #{Round.count} total"

  puts "\n🎉 Development database seeding completed!"
  puts "\n📊 Summary:"
  puts "👤 Users: #{User.count} (#{User.admins.count} admin, #{User.players.count} players)"
  puts "🏆 Tournaments: #{Tournament.count}"
  puts "⛳ Teams: #{Team.count}"
  puts "🎯 Rounds: #{Round.count}"
  puts "👥 Team Memberships: #{TeamMembership.count}"
else
  puts "ℹ️  Production environment - only ensuring admin user exists"
  puts "ℹ️  Set SEED_DB=true environment variable to run full seeding if needed"
end

puts "\n🔐 Login credentials:"
puts "Admin: admin@bullpencup.com / password123"
if Rails.env.development?
  puts "Users: Use any email from the list above / password123"
end

puts "\n✨ Seeding completed!"
puts "🚀 Ready for #{Rails.env}!"
