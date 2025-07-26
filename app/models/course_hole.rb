class CourseHole < ApplicationRecord
  belongs_to :course_tee
  has_one :course, through: :course_tee

  # Validations
  validates :hole_number, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 18, only_integer: true }
  validates :par, presence: true,
            numericality: { greater_than: 2, less_than_or_equal_to: 6, only_integer: true }
  validates :yardage, presence: true,
            numericality: { greater_than: 50, less_than: 800, only_integer: true }
  validates :handicap, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 18, only_integer: true }

  # Unique constraint validation
  validates :hole_number, uniqueness: { scope: :course_tee_id }
  validates :handicap, uniqueness: { scope: :course_tee_id }

  # Callbacks
  after_save :update_tee_totals
  after_destroy :update_tee_totals

  # Scopes
  scope :by_hole_number, -> { order(:hole_number) }
  scope :by_handicap, -> { order(:handicap) }
  scope :par_3s, -> { where(par: 3) }
  scope :par_4s, -> { where(par: 4) }
  scope :par_5s, -> { where(par: 5) }

  # Methods
  def display_name
    "Hole #{hole_number}"
  end

  def difficulty_rating
    case handicap
    when 1..6 then "Hard"
    when 7..12 then "Medium"
    when 13..18 then "Easy"
    end
  end

  def par_description
    case par
    when 3 then "Par 3"
    when 4 then "Par 4"
    when 5 then "Par 5"
    when 6 then "Par 6"
    else "Par #{par}"
    end
  end

  # Convert to API-like structure for compatibility
  def to_api_format
    {
      'par' => par,
      'yardage' => yardage,
      'handicap' => handicap
    }
  end

  private

  def update_tee_totals
    return unless course_tee.holes_complete?
    
    course_tee.update_columns(
      total_yards: course_tee.course_holes.sum(:yardage),
      par_total: course_tee.course_holes.sum(:par)
    )
  end
end
