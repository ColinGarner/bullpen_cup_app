class Match < ApplicationRecord
  belongs_to :round
  belongs_to :team_a, class_name: "Team"
  belongs_to :team_b, class_name: "Team"
  belongs_to :winner_team, class_name: "Team", optional: true
  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players, source: :user

  # Enums for match types and status
  enum :match_type, {
    fourball_match_play: "fourball_match_play",
    alt_shot_match_play: "alt_shot_match_play",
    singles_match_play: "singles_match_play",
    stableford: "stableford"
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
    when "fourball_match_play", "alt_shot_match_play"
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
