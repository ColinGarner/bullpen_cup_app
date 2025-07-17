class TeamMembership < ApplicationRecord
  belongs_to :team
  belongs_to :user
  
  # Validations
  validates :user_id, uniqueness: { scope: :team_id, message: "is already on this team" }
  validates :joined_at, presence: true
  
  # Callbacks
  before_validation :set_joined_at, on: :create
  
  # Scopes
  scope :by_join_date, -> { order(:joined_at) }
  scope :recent, -> { order(joined_at: :desc) }
  
  # Instance methods
  def captain?
    team.captain == user
  end
  
  private
  
  def set_joined_at
    self.joined_at ||= Time.current
  end
end
