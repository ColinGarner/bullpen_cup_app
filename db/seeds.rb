# Clear existing data
puts "Clearing existing data..."
MatchPlayer.destroy_all
Match.destroy_all
Round.destroy_all

# Clear tournament team references first to avoid foreign key violations
puts "Clearing tournament team references..."
Tournament.update_all(team_a_id: nil, team_b_id: nil)

Tournament.destroy_all
TeamMembership.destroy_all
Team.destroy_all
GroupMembership.destroy_all
Group.destroy_all
User.destroy_all

puts "Creating groups..."

# Create Groups
pebble_beach = Group.create!(
  name: "Pebble Beach Golf Club",
  slug: "pebble-beach",
  description: "Premier golf club featuring championship tournaments and beautiful coastal views.",
  contact_email: "info@pebblebeach.golf",
  contact_phone: "(831) 647-7500",
  address: "1700 17-Mile Drive, Pebble Beach, CA 93953",
  active: true
)

augusta_national = Group.create!(
  name: "Augusta National Golf Club",
  slug: "augusta-national",
  description: "Home of the Masters Tournament and one of the most prestigious golf clubs in the world.",
  contact_email: "contact@augusta.golf",
  contact_phone: "(706) 667-6000",
  address: "2604 Washington Road, Augusta, GA 30904",
  active: true
)

pinehurst = Group.create!(
  name: "Pinehurst Resort",
  slug: "pinehurst",
  description: "Historic golf resort in North Carolina featuring multiple championship courses.",
  contact_email: "golf@pinehurst.com",
  contact_phone: "(855) 235-8507",
  address: "1 Carolina Vista Dr, Pinehurst, NC 28374",
  active: true
)

puts "Creating users..."

# Create Admin Users for each group
admin_users = []

admin_users << User.create!(
  first_name: "James",
  last_name: "Mitchell",
  email: "james.mitchell@pebblebeach.golf",
  password: "password123",
  handicap: 8.5,
  admin: false
)

admin_users << User.create!(
  first_name: "Sarah",
  last_name: "Johnson",
  email: "sarah.johnson@augusta.golf",
  password: "password123",
  handicap: 12.0,
  admin: false
)

admin_users << User.create!(
  first_name: "Robert",
  last_name: "Williams",
  email: "robert.williams@pinehurst.com",
  password: "password123",
  handicap: 6.2,
  admin: false
)

# Create Global Admin
global_admin = User.create!(
  first_name: "System",
  last_name: "Administrator",
      email: "admin@scorecard.golf",
  password: "password123",
  handicap: 15.0,
  admin: true
)

puts "Creating group memberships..."

# Add admin users to their respective groups as admins
pebble_beach.add_member(admin_users[0], role: 'admin')
augusta_national.add_member(admin_users[1], role: 'admin')
pinehurst.add_member(admin_users[2], role: 'admin')

# Add global admin to all groups
pebble_beach.add_member(global_admin, role: 'admin')
augusta_national.add_member(global_admin, role: 'admin')
pinehurst.add_member(global_admin, role: 'admin')

# Create regular members for each group
puts "Creating regular members..."

pebble_members = []
pebble_names = [
  [ "David", "Anderson" ], [ "Emma", "Brown" ], [ "Michael", "Davis" ],
  [ "Sarah", "Garcia" ], [ "Christopher", "Wilson" ]
]
pebble_names.each_with_index do |(first, last), i|
  user = User.create!(
    first_name: first,
    last_name: last,
    email: "#{first.downcase}.#{last.downcase}@pebblebeach.golf",
    password: "password123",
    handicap: rand(0.0..25.0).round(1)
  )
  pebble_beach.add_member(user, role: 'member')
  pebble_members << user
end

augusta_members = []
augusta_names = [
  [ "Jennifer", "Miller" ], [ "Robert", "Taylor" ], [ "Amanda", "Thomas" ],
  [ "Daniel", "Jackson" ], [ "Ashley", "White" ]
]
augusta_names.each_with_index do |(first, last), i|
  user = User.create!(
    first_name: first,
    last_name: last,
    email: "#{first.downcase}.#{last.downcase}@augusta.golf",
    password: "password123",
    handicap: rand(0.0..25.0).round(1)
  )
  augusta_national.add_member(user, role: 'member')
  augusta_members << user
end

pinehurst_members = []
pinehurst_names = [
  [ "Matthew", "Harris" ], [ "Jessica", "Martin" ], [ "Andrew", "Thompson" ],
  [ "Nicole", "Garcia" ], [ "Kevin", "Martinez" ]
]
pinehurst_names.each_with_index do |(first, last), i|
  user = User.create!(
    first_name: first,
    last_name: last,
    email: "#{first.downcase}.#{last.downcase}@pinehurst.com",
    password: "password123",
    handicap: rand(0.0..25.0).round(1)
  )
  pinehurst.add_member(user, role: 'member')
  pinehurst_members << user
end

puts "Creating tournaments..."

# Create tournaments for each group
pebble_tournament = Tournament.create!(
  name: "Pebble Beach Pro-Am Championship",
  description: "Annual championship tournament featuring professional and amateur players.",
  start_date: 2.months.from_now,
  end_date: 2.months.from_now + 3.days,
  venue: "Pebble Beach Golf Links",
  group: pebble_beach,
  created_by: admin_users[0]
)

augusta_tournament = Tournament.create!(
  name: "Augusta Spring Invitational",
  description: "Exclusive member tournament played on the famous Augusta National course.",
  start_date: 3.months.from_now,
  end_date: 3.months.from_now + 4.days,
  venue: "Augusta National Golf Course",
  group: augusta_national,
  created_by: admin_users[1]
)

pinehurst_tournament = Tournament.create!(
  name: "Pinehurst Summer Classic",
  description: "Multi-course tournament featuring Pinehurst's championship layouts.",
  start_date: 4.months.from_now,
  end_date: 4.months.from_now + 5.days,
  venue: "Pinehurst Resort & Country Club",
  group: pinehurst,
  created_by: admin_users[2]
)

puts "Creating teams..."

# Create teams for each tournament
[ pebble_tournament, augusta_tournament, pinehurst_tournament ].each_with_index do |tournament, group_index|
  members = case group_index
  when 0 then pebble_members
  when 1 then augusta_members
  when 2 then pinehurst_members
  end

  # Create 2 teams per tournament
  teams = []
  2.times do |team_index|
    team = Team.create!(
      name: "Team #{[ 'Alpha', 'Bravo' ][team_index]}",
      tournament: tournament,
      captain: members[team_index * 2]
    )

    # Add 3 additional players to each team
    (1..3).each do |player_index|
      team.add_player(members[team_index * 2 + player_index])
    end

    teams << team
  end

  # Assign teams to tournament
  tournament.update!(team_a: teams[0], team_b: teams[1])
end

puts "\n" + "="*50
puts "SEED DATA SUMMARY"
puts "="*50
puts "Groups created: #{Group.count}"
puts "Users created: #{User.count}"
puts "Group memberships created: #{GroupMembership.count}"
puts "Tournaments created: #{Tournament.count}"
puts "Teams created: #{Team.count}"
puts "\nLogin credentials:"
puts "Global Admin: admin@scorecard.golf / password123"
puts "Pebble Beach Admin: james.mitchell@pebblebeach.golf / password123"
puts "Augusta Admin: sarah.johnson@augusta.golf / password123"
puts "Pinehurst Admin: robert.williams@pinehurst.com / password123"
puts "="*50
