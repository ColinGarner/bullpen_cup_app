class Tournament < ApplicationRecord
  include TenantScoped

  belongs_to :created_by, class_name: "User"
  belongs_to :group
  belongs_to :team_a, class_name: "Team", optional: true
  belongs_to :team_b, class_name: "Team", optional: true

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

  # 5GKLSL

  # Custom validations
  validate :end_date_after_start_date
  validate :teams_must_be_different
  validate :teams_must_belong_to_tournament
  validate :tournament_must_have_at_most_two_teams

  # Scopes - now based on dates and cancelled status
  scope :upcoming, -> { where(cancelled: false).where("start_date > ?", Date.current) }
  scope :active, -> { where(cancelled: false).where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :completed, -> { where(cancelled: false).where("end_date < ?", Date.current) }
  scope :cancelled, -> { where(cancelled: true) }
  scope :by_start_date, -> { order(:start_date) }
  scope :in_group, ->(group) { where(group: group) }

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

  # Group-related methods
  def group_name
    group&.name
  end

  def group_slug
    group&.slug
  end

  def at_team_limit?
    teams.count >= 2
  end

  def next_team_role
    case teams.count
    when 0
      "Team A"
    when 1
      "Team B"
    else
      nil
    end
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def teams_must_be_different
    return unless team_a && team_b
    errors.add(:team_b, "cannot be the same as Team A") if team_a == team_b
  end

  def teams_must_belong_to_tournament
    if team_a && !teams.include?(team_a)
      errors.add(:team_a, "must belong to this tournament")
    end

    if team_b && !teams.include?(team_b)
      errors.add(:team_b, "must belong to this tournament")
    end
  end

  def tournament_must_have_at_most_two_teams
    # Only validate after tournament is persisted and has teams
    return unless persisted? && teams.count > 0

    if teams.count > 2
      errors.add(:base, "Tournament must not have more than 2 teams")
    end
  end

  # Helper methods for team management
  def teams_assigned?
    team_a.present? && team_b.present?
  end
end
