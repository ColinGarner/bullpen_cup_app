class Match < ApplicationRecord
  belongs_to :round
  belongs_to :team_a, class_name: "Team"
  belongs_to :team_b, class_name: "Team"
  belongs_to :winner_team, class_name: "Team", optional: true
  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players, source: :user
  has_many :scores, dependent: :destroy

  # Enums for match types and status
  enum :match_type, {
    fourball_match_play: "fourball_match_play",
    alt_shot_match_play: "alt_shot_match_play",
    singles_match_play: "singles_match_play",
    stableford: "stableford",
    stableford_match_play: "stableford_match_play",
    scramble_match_play: "scramble_match_play"
  }

  enum :status, {
    upcoming: "upcoming",
    active: "active",
    completed: "completed",
    cancelled: "cancelled"
  }

  # Validations
  validates :match_type, presence: true
  validates :status, presence: true
  validate :teams_must_be_different
  validate :teams_must_belong_to_tournament
  validate :winner_must_be_competing_team
  # Simple golf course validations
  validates :golf_course_name, length: { maximum: 200 }, allow_blank: true
  validates :golf_course_location, length: { maximum: 200 }, allow_blank: true

  # Scopes
  scope :by_round, ->(round) { where(round: round) }
  scope :for_team, ->(team) { where("team_a_id = ? OR team_b_id = ?", team.id, team.id) }
  scope :by_match_type, ->(type) { where(match_type: type) }
  scope :by_status, ->(status) { where(status: status) }

  # Helper methods
  def opposing_team(team)
    return team_b if team == team_a
    return team_a if team == team_b
    nil
  end

  def players_for_team(team)
    match_players.where(team: team).includes(:user).map(&:user)
  end

  def team_a_players
    players_for_team(team_a)
  end

  def team_b_players
    players_for_team(team_b)
  end

  def both_teams
    [ team_a, team_b ]
  end

  def tournament
    round.tournament
  end

  # Player count validation based on match type
  def valid_player_count?
    expected_players = expected_player_count
    return false if match_players.count != expected_players

    # Check even distribution between teams
    team_a_count = match_players.where(team: team_a).count
    team_b_count = match_players.where(team: team_b).count

    team_a_count == team_b_count && team_a_count == (expected_players / 2)
  end

  def expected_player_count
    case match_type
    when "singles_match_play"
      2 # 1 per team
    when "fourball_match_play", "alt_shot_match_play", "scramble_match_play"
      4 # 2 per team
    when "stableford"
      # For now, assume stableford can be either 2 or 4 players
      # This could be made configurable later
      2
    else
      0
    end
  end

  def players_per_team
    expected_player_count / 2
  end

  # Status transition methods
  def start!
    update!(status: "active")
  end

  def complete_with_winner!(winning_team)
    update!(
      status: "completed",
      winner_team: winning_team,
      completed_at: Time.current
    )
  end

  def cancel!
    update!(status: "cancelled")
  end

  # Display helpers
  def display_name
    "#{team_a.name} vs #{team_b.name}"
  end

  def match_type_display
    match_type.humanize.titleize
  end

  def status_badge_class
    case status
    when "upcoming" then "bg-blue-100 text-blue-800"
    when "active" then "bg-green-100 text-green-800"
    when "completed" then "bg-gray-100 text-gray-800"
    when "cancelled" then "bg-red-100 text-red-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def winner_display
    return "TBD" unless completed?
    return "Draw" unless winner_team
    winner_team.name
  end

  # Golf course helper methods
  def has_golf_course?
    golf_course_id.present?
  end

  def golf_course_display
    return "No course selected" unless has_golf_course?
    golf_course_name.present? ? golf_course_name : "Course ##{golf_course_id}"
  end

  def course_setup_complete?
    golf_course_id.present?
  end

  def tee_display
    return "TBD" unless has_golf_course? && selected_tee_name.present?
    "#{selected_tee_name}"
  end

  def course_par_display
    return "TBD" unless has_golf_course?
    course_par
  end

  def scheduled_for_today?
    return false unless scheduled_time

    # Handle timezone differences by being more flexible about "today"
    # Consider a match available for scoring if:
    # 1. It's scheduled for today in server timezone
    # 2. It's scheduled within the last 24 hours (handles timezone differences)
    # 3. It's scheduled for tomorrow but very early (handles timezone ahead of server)
    
    current_time = Time.current
    today = Date.today
    
    # Extract the scheduled date
    scheduled_date = Date.new(scheduled_time.year, scheduled_time.month, scheduled_time.day)
    
    # Check if it's today in server timezone
    return true if scheduled_date == today
    
    # Check if it's within a reasonable window (yesterday to tomorrow)
    # This handles timezone differences where user might be up to 12 hours ahead/behind
    yesterday = today - 1.day
    tomorrow = today + 1.day
    
    if scheduled_date == yesterday
      # If scheduled yesterday, only allow if it's within last 18 hours
      # (handles case where server is ahead of user's timezone)
      time_diff = current_time - scheduled_time
      return time_diff <= 18.hours
    elsif scheduled_date == tomorrow
      # If scheduled tomorrow, only allow if it's very early tomorrow
      # (handles case where server is behind user's timezone)
      time_diff = scheduled_time - current_time  
      return time_diff <= 6.hours
    end
    
    false
  end

  # Check if this is a scramble format where teams share a single score
  def scramble_format?
    match_type == "scramble_match_play"
  end

  # Calculate team handicap for scramble format: 35% of low + 15% of high
  def calculate_scramble_team_handicap(team)
    return 0 unless scramble_format?

    players = players_for_team(team)
    return 0 unless players.count == 2

    # Calculate course handicaps for both players
    course_handicaps = players.map { |p| calculate_course_handicap_for_player(p) }.compact
    return 0 unless course_handicaps.count == 2

    # Sort to get low and high handicaps
    low_handicap, high_handicap = course_handicaps.sort

    # 35% of low + 15% of high, rounded to nearest integer
    ((low_handicap * 0.35) + (high_handicap * 0.15)).round
  end

  # Helper method to calculate course handicap for a player
  def calculate_course_handicap_for_player(player)
    return 0 unless player.handicap && selected_tee_name

    # Get tee data from stored course data
    course_data = holes_data&.dig("course_data")
    return 0 unless course_data

    # Find the selected tee data
    tee_data = find_tee_data_in_course(selected_tee_name, course_data)
    return 0 unless tee_data

    # Course Handicap = Handicap Index × (Slope Rating ÷ 113)
    slope_rating = tee_data["slope_rating"] || 113
    (player.handicap.to_f * (slope_rating / 113.0)).round
  end

  private

  # Helper to find tee data within course data
  def find_tee_data_in_course(tee_name, course_data)
    return nil unless course_data&.dig("course", "tees")

    course_data["course"]["tees"].each do |gender, gender_tees|
      gender_tees.each do |tee|
        return tee if tee["tee_name"] == tee_name
      end
    end

    nil
  end

  private

  def teams_must_be_different
    return unless team_a && team_b
    errors.add(:team_b, "cannot be the same as Team A") if team_a == team_b
  end

  def teams_must_belong_to_tournament
    return unless round && team_a && team_b

    tournament = round.tournament

    unless team_a.tournament == tournament
      errors.add(:team_a, "must belong to the same tournament as the round")
    end

    unless team_b.tournament == tournament
      errors.add(:team_b, "must belong to the same tournament as the round")
    end
  end

  def winner_must_be_competing_team
    return unless winner_team

    unless [ team_a, team_b ].include?(winner_team)
      errors.add(:winner_team, "must be one of the competing teams")
    end
  end
end
