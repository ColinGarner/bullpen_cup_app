class Tournament < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  # New relationships
  has_many :teams, dependent: :destroy
  has_many :rounds, -> { order(:round_number) }, dependent: :destroy
  has_many :team_memberships, through: :teams
  has_many :participants, through: :team_memberships, source: :user

  # Validations
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, length: { maximum: 1000 }
  validates :start_date, :end_date, presence: true
  validates :venue, length: { maximum: 200 }
  validates :cancelled, inclusion: { in: [ true, false ] }

  # Custom validation to ensure end_date is after start_date
  validate :end_date_after_start_date

  # Scopes - now based on dates and cancelled status
  scope :upcoming, -> { where(cancelled: false).where("start_date > ?", Date.current) }
  scope :active, -> { where(cancelled: false).where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :completed, -> { where(cancelled: false).where("end_date < ?", Date.current) }
  scope :cancelled, -> { where(cancelled: true) }
  scope :by_start_date, -> { order(:start_date) }

  # Computed status method
  def status
    return "cancelled" if cancelled?

    current_date = Date.current

    if current_date < start_date
      "upcoming"
    elsif current_date >= start_date && current_date <= end_date
      "active"
    else
      "completed"
    end
  end

  # Status query methods
  def upcoming?
    !cancelled? && Date.current < start_date
  end

  def active?
    !cancelled? && Date.current >= start_date && Date.current <= end_date
  end

  def completed?
    !cancelled? && Date.current > end_date
  end

  def cancelled?
    cancelled == true
  end

  # Only keep cancel! method - start and complete are automatic based on dates
  def cancel!
    update!(cancelled: true)
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
    when "upcoming" then "bg-blue-100 text-blue-800"
    when "active" then "bg-green-100 text-green-800"
    when "completed" then "bg-gray-100 text-gray-800"
    when "cancelled" then "bg-red-100 text-red-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
