class Tournament < ApplicationRecord
  belongs_to :created_by, class_name: 'User'
  
  # New relationships
  has_many :teams, dependent: :destroy
  has_many :rounds, -> { order(:round_number) }, dependent: :destroy
  has_many :team_memberships, through: :teams
  has_many :participants, through: :team_memberships, source: :user
  
  # Validations
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, length: { maximum: 1000 }
  validates :start_date, :end_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[upcoming active completed cancelled] }
  validates :venue, length: { maximum: 200 }
  
  # Custom validation to ensure end_date is after start_date
  validate :end_date_after_start_date
  
  # Scopes
  scope :upcoming, -> { where(status: 'upcoming') }
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :by_start_date, -> { order(:start_date) }
  
  # Status methods
  def upcoming?
    status == 'upcoming'
  end
  
  def active?
    status == 'active'
  end
  
  def completed?
    status == 'completed'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  # Status transitions
  def start!
    update!(status: 'active')
  end
  
  def complete!
    update!(status: 'completed')
  end
  
  def cancel!
    update!(status: 'cancelled')
  end
  
  # Helper methods for teams and rounds
  def team_count
    teams.count
  end
  
  def participant_count
    team_memberships.count
  end
  
  def round_count
    rounds.count
  end
  
  def next_round_number
    (rounds.maximum(:round_number) || 0) + 1
  end
  
  def current_round
    rounds.active.first
  end
  
  def upcoming_rounds
    rounds.upcoming.by_round_number
  end
  
  def completed_rounds
    rounds.completed.by_round_number
  end
  
  # Helper methods
  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i + 1
  end
  
  def status_badge_class
    case status
    when 'upcoming' then 'bg-blue-100 text-blue-800'
    when 'active' then 'bg-green-100 text-green-800'
    when 'completed' then 'bg-gray-100 text-gray-800'
    when 'cancelled' then 'bg-red-100 text-red-800'
    else 'bg-gray-100 text-gray-800'
    end
  end
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
