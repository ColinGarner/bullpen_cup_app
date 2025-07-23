class Team < ApplicationRecord
  belongs_to :tournament
  belongs_to :captain, class_name: "User"

  has_many :team_memberships, dependent: :destroy
  has_many :players, through: :team_memberships, source: :user

  # Match associations
  has_many :won_matches, class_name: "Match", foreign_key: "winner_team_id"
  has_many :match_players, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :name, uniqueness: { scope: :tournament_id, message: "already exists in this tournament" }

  # Callbacks
  after_create :add_captain_as_player

  # Scopes
  scope :by_name, -> { order(:name) }

  # Instance methods
  def player_count
    team_memberships.count
  end

  def add_player(user)
    team_memberships.find_or_create_by(user: user) do |membership|
      membership.joined_at = Time.current
    end
  end

  def remove_player(user)
    return false if user == captain # Can't remove captain
    team_memberships.find_by(user: user)&.destroy
  end

  def captain?(user)
    captain == user
  end

  def player?(user)
    players.include?(user)
  end

  # Match helper methods
  def matches
    Match.joins(round: :tournament).where("tournaments.team_a_id = ? OR tournaments.team_b_id = ?", id, id)
  end

  def match_count
    matches.count
  end

  def wins_count
    won_matches.count
  end

  private

  def add_captain_as_player
    # Ensure captain is added as a team member after team creation
    add_player(captain) if captain
  end
end
