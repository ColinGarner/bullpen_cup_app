class MatchPlayer < ApplicationRecord
  belongs_to :match
  belongs_to :team
  belongs_to :user
  
  # Validations
  validates :match, presence: true
  validates :team, presence: true
  validates :user, presence: true
  validate :user_must_be_team_member
  validate :team_must_be_in_match
  validate :user_not_already_in_match
  
  # Scopes
  scope :for_match, ->(match) { where(match: match) }
  scope :for_team, ->(team) { where(team: team) }
  scope :for_user, ->(user) { where(user: user) }
  
  # Helper methods
  def player_name
    user.display_name
  end
  
  def team_name
    team.name
  end
  
  def match_display
    match.display_name
  end
  
  private
  
  def user_must_be_team_member
    return unless user && team
    
    unless team.players.include?(user)
      errors.add(:user, "must be a member of the specified team")
    end
  end
  
  def team_must_be_in_match
    return unless team && match
    
    unless [match.team_a, match.team_b].include?(team)
      errors.add(:team, "must be one of the teams in this match")
    end
  end
  
  def user_not_already_in_match
    return unless user && match && persisted? == false
    
    if match.match_players.exists?(user: user)
      errors.add(:user, "is already in this match")
    end
  end
end 