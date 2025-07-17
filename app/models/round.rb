class Round < ApplicationRecord
  belongs_to :tournament
  
  # Validations
  validates :round_number, presence: true, uniqueness: { scope: :tournament_id }
  validates :round_number, numericality: { greater_than: 0 }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :status, presence: true, inclusion: { in: %w[upcoming active completed cancelled] }
  
  # Scopes
  scope :by_round_number, -> { order(:round_number) }
  scope :upcoming, -> { where(status: 'upcoming') }
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :by_date, -> { order(:date) }
  
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
  
  # Helper methods
  def status_badge_class
    case status
    when 'upcoming' then 'bg-blue-100 text-blue-800'
    when 'active' then 'bg-green-100 text-green-800'
    when 'completed' then 'bg-gray-100 text-gray-800'
    when 'cancelled' then 'bg-red-100 text-red-800'
    else 'bg-gray-100 text-gray-800'
    end
  end
  
  def formatted_date
    return 'TBD' unless date
    date.strftime('%B %d, %Y')
  end
end
