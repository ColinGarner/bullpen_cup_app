class Score < ApplicationRecord
  belongs_to :match
  belongs_to :user

  # Validations
  validates :hole_number, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 18 }
  validates :strokes, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 15 }
  validates :net_strokes, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 15 }
  validates :handicap_used, presence: true,
            numericality: { greater_than_or_equal_to: -10.0, less_than_or_equal_to: 54.0 }
  validates :strokes_received_on_hole, presence: true,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }
  validates :hole_result, inclusion: { in: %w[won lost halved pending], allow_nil: true }

  # Scopes
  scope :for_match, ->(match) { where(match: match) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_hole, ->(hole_number) { where(hole_number: hole_number) }
  scope :completed_holes, -> { where.not(strokes: nil) }
  scope :match_play_results, -> { where.not(hole_result: nil) }

  # Class methods
  def self.for_match_and_hole(match, hole_number)
    where(match: match, hole_number: hole_number)
  end

  def self.total_strokes_for_user(user, match)
    where(user: user, match: match).sum(:strokes)
  end

  def self.total_net_strokes_for_user(user, match)
    where(user: user, match: match).sum(:net_strokes)
  end

  # Instance methods
  def gross_score
    strokes
  end

  def net_score
    net_strokes
  end

  def received_strokes?
    strokes_received_on_hole > 0
  end

  def calculate_net_score
    strokes - strokes_received_on_hole
  end

  def match_play_won?
    hole_result == "won"
  end

  def match_play_lost?
    hole_result == "lost"
  end

  def match_play_halved?
    hole_result == "halved"
  end

  def match_play_pending?
    hole_result == "pending" || hole_result.nil?
  end

  # Calculate and set net score based on gross score and strokes received
  def calculate_and_set_net_score!
    update!(net_strokes: calculate_net_score)
  end

  # Display helpers
  def score_display
    if received_strokes?
      "#{strokes} (#{net_strokes} net, #{strokes_received_on_hole} stroke#{'s' if strokes_received_on_hole > 1})"
    else
      strokes.to_s
    end
  end

  def hole_result_display
    case hole_result
    when "won" then "✓"
    when "lost" then "✗"
    when "halved" then "½"
    else "-"
    end
  end

  # Historical handicap method
  def handicap_at_time_of_scoring
    handicap_used
  end

  def par_for_hole
    # This would come from the course data stored in match.holes_data
    # For now, returning a default
    match.holes_data&.dig(hole_number.to_s, "par") || 4
  end

  def handicap_index_for_hole
    # This would come from the course data stored in match.holes_data
    # For now, returning a default
    match.holes_data&.dig(hole_number.to_s, "handicap") || 10
  end
end
