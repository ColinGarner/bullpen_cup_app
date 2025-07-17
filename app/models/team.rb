class Team < ApplicationRecord
  belongs_to :tournament
  belongs_to :captain, class_name: 'User'
  
  has_many :team_memberships, dependent: :destroy
  has_many :players, through: :team_memberships, source: :user
  
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
  
  private
  
  def add_captain_as_player
    # Ensure captain is added as a team member after team creation
    add_player(captain) if captain
  end
end
