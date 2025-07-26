class Course < ApplicationRecord
  has_many :course_tees, dependent: :destroy
  has_many :course_holes, through: :course_tees
  has_many :matches, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { maximum: 200 }
  validates :club_name, presence: true, length: { maximum: 200 }
  validates :city, length: { maximum: 100 }, allow_blank: true
  validates :state, length: { maximum: 50 }, allow_blank: true
  validates :country, presence: true, length: { maximum: 100 }
  validates :api_course_id, uniqueness: true, allow_blank: true
  
  # Prevent duplicate manual courses with same name and club
  validates :name, uniqueness: { 
    scope: [:club_name, :city, :state], 
    message: "already exists for this club and location" 
  }

  # Scopes
  scope :api_courses, -> { where.not(api_course_id: nil) }
  scope :manual_courses, -> { where(api_course_id: nil) }
  scope :by_location, ->(city, state) { where(city: city, state: state) }

  # Methods
  def display_name
    name
  end

  def full_location
    parts = []
    parts << city if city.present?
    parts << state if state.present?
    parts << country if country.present? && country != 'United States'
    parts.join(', ')
  end

  def location_display
    full_location.presence || 'Location not specified'
  end

  def from_api?
    api_course_id.present?
  end

  def manual_entry?
    api_course_id.blank?
  end

  # Convert to API-like structure for compatibility
  def to_api_format
    {
      'course' => {
        'club_name' => club_name,
        'course_name' => name,
        'location' => {
          'address' => address,
          'city' => city,
          'state' => state,
          'country' => country
        },
        'tees' => {
          'male' => course_tees.where(gender: 'male').map(&:to_api_format),
          'female' => course_tees.where(gender: 'female').map(&:to_api_format)
        }
      }
    }
  end

  # Search functionality
  def self.search(query)
    return none if query.blank? || query.length < 3

    where(
      "name ILIKE ? OR club_name ILIKE ? OR city ILIKE ?",
      "%#{query}%", "%#{query}%", "%#{query}%"
    )
  end

  # Create from API data
  def self.create_from_api_data(api_data, api_course_id)
    course_info = api_data['course']
    location = course_info['location'] || {}

    course = create!(
      name: course_info['course_name'],
      club_name: course_info['club_name'],
      address: location['address'],
      city: location['city'],
      state: location['state'],
      country: location['country'] || 'United States',
      api_course_id: api_course_id.to_s
    )

    # Create tees
    course_info['tees']&.each do |gender, tees|
      tees.each do |tee_data|
        course_tee = course.course_tees.create!(
          tee_name: tee_data['tee_name'],
          gender: gender,
          course_rating: tee_data['course_rating'],
          slope_rating: tee_data['slope_rating'],
          total_yards: tee_data['total_yards'],
          total_meters: tee_data['total_meters'] || (tee_data['total_yards'] * 0.9144).round,
          par_total: tee_data['par_total']
        )

        # Create holes
        tee_data['holes']&.each_with_index do |hole_data, index|
          course_tee.course_holes.create!(
            hole_number: index + 1,
            par: hole_data['par'],
            yardage: hole_data['yardage'],
            handicap: hole_data['handicap']
          )
        end
      end
    end

    course
  end
end
