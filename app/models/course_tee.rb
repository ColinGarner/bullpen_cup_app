class CourseTee < ApplicationRecord
  belongs_to :course
  has_many :course_holes, dependent: :destroy

  # Validations
  validates :tee_name, presence: true, length: { maximum: 100 }
  validates :gender, presence: true, inclusion: { in: %w[male female] }
  validates :course_rating, presence: true, 
            numericality: { greater_than: 50, less_than: 85 }
  validates :slope_rating, presence: true,
            numericality: { greater_than: 55, less_than: 155, only_integer: true }
  validates :total_yards, presence: true,
            numericality: { greater_than: 1000, less_than: 8000, only_integer: true }
  validates :total_meters, presence: true,
            numericality: { greater_than: 900, less_than: 7500, only_integer: true }
  validates :par_total, presence: true,
            numericality: { greater_than: 60, less_than: 80, only_integer: true }

  # Unique constraint validation
  validates :tee_name, uniqueness: { scope: [:course_id, :gender] }

  # Callbacks
  before_save :calculate_total_meters, if: :total_yards_changed?

  # Scopes
  scope :male, -> { where(gender: 'male') }
  scope :female, -> { where(gender: 'female') }
  scope :by_yardage, -> { order(:total_yards) }

  # Methods
  def display_name
    "#{tee_name} (#{gender.capitalize})"
  end

  def full_display_name
    "#{course.name} - #{display_name}"
  end

  def holes_complete?
    course_holes.count == 18
  end

  def recalculate_totals!
    return unless holes_complete?

    update!(
      total_yards: course_holes.sum(:yardage),
      par_total: course_holes.sum(:par)
    )
  end

  # Convert to API-like structure for compatibility
  def to_api_format
    {
      'tee_name' => tee_name,
      'course_rating' => course_rating.to_f,
      'slope_rating' => slope_rating,
      'total_yards' => total_yards,
      'total_meters' => total_meters,
      'number_of_holes' => 18,
      'par_total' => par_total,
      'holes' => course_holes.order(:hole_number).map(&:to_api_format)
    }
  end

  private

  def calculate_total_meters
    self.total_meters = (total_yards * 0.9144).round if total_yards.present?
  end
end
