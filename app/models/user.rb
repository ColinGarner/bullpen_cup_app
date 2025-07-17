class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validations for name fields
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }

  # Team relationships
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :captained_teams, class_name: 'Team', foreign_key: 'captain_id', dependent: :destroy
  has_many :created_tournaments, class_name: 'Tournament', foreign_key: 'created_by_id', dependent: :destroy

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

  def display_name
    "#{first_name} #{last_name}".strip
  end

  def full_name
    display_name
  end

  def initials
    "#{first_name.first}#{last_name.first}".upcase if first_name.present? && last_name.present?
  end
end
