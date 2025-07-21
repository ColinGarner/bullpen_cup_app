class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validations for name fields
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }

  # Validations for handicap
  validates :handicap, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 54,
    allow_nil: true
  }

  # Group relationships
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships

  # Team relationships
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :captained_teams, class_name: "Team", foreign_key: "captain_id", dependent: :destroy
  has_many :created_tournaments, class_name: "Tournament", foreign_key: "created_by_id", dependent: :destroy

  # Match associations
  has_many :match_players, dependent: :destroy
  has_many :matches, through: :match_players
  has_many :scores, dependent: :destroy

  # Admin functionality
  scope :admins, -> { where(admin: true) }
  scope :players, -> { where(admin: false) }

  def admin?
    admin
  end

  def make_admin!
    update!(admin: true)
  end

  def remove_admin!
    update!(admin: false)
  end

  # Group-related methods
  def group_admin?(group)
    group_memberships.find_by(group: group, role: "admin").present?
  end

  def group_member?(group)
    groups.include?(group)
  end

  def groups_as_admin
    groups.joins(:group_memberships).where(group_memberships: { role: "admin", user_id: id })
  end

  def groups_as_member
    groups.joins(:group_memberships).where(group_memberships: { role: "member", user_id: id })
  end

  def join_group(group, role: "member")
    group.add_member(self, role: role)
  end

  def leave_group(group)
    group.remove_member(self)
  end

  # Team-related methods
  def captain_of?(team)
    captained_teams.include?(team)
  end

  def member_of?(team)
    teams.include?(team)
  end

  def tournaments_as_participant
    Tournament.joins(:team_memberships).where(team_memberships: { user_id: id }).distinct
  end

  def tournaments_as_captain
    Tournament.joins(:teams).where(teams: { captain_id: id }).distinct
  end

  # Scoped tournament methods by group
  def tournaments_in_group(group)
    tournaments_as_participant.where(group: group)
  end

  def tournaments_created_in_group(group)
    created_tournaments.where(group: group)
  end

  def display_name
    "#{first_name} #{last_name}".strip
  end

  def full_name
    display_name
  end

  def initials
    "#{first_name.first}#{last_name.first}".upcase if first_name.present? && last_name.present?
  end

  def formatted_handicap
    return "N/A" unless handicap.present?
    handicap % 1 == 0 ? handicap.to_i.to_s : handicap.to_s
  end
end
