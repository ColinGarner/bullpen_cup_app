class GolfCourseApiService
  include HTTParty
  base_uri ENV.fetch("GOLF_COURSE_API_BASE_URL", "https://api.golfcourseapi.com")

  def initialize
    @api_key = ENV.fetch("GOLF_COURSE_API_KEY", nil)
    raise "Golf Course API key is not set" unless @api_key.present?
  end

  def search_courses(search_term)
    return unless search_term.present? && search_term.length >= 3

    begin
      response = self.class.get(
        "/v1/search",
        headers: { "Authorization" => "Key #{@api_key}" },
        query: { search_query: search_term }
      )

      parsed_response = handle_response(response)

      if parsed_response && parsed_response.is_a?(Hash) && parsed_response["courses"]
        parsed_response["courses"]
      else
        []
      end
    rescue => e
      Rails.logger.error "Golf Course API Error: #{e.class}: #{e.message}"
      []
    end
  end

  def get_course_details(course_id)
    response = self.class.get(
      "#{base_uri}/courses/#{course_id}",
      headers: {
        "Authorization" => "Key #{@api_key}"
      }
    )

    handle_response(response)
  end

  private

  def handle_response(response)
    if response.success?
      begin
        response.parsed_response
      rescue => e
        Rails.logger.error "Golf Course API Parse Error: #{e.class}: #{e.message}"

        # Try manual JSON parsing as fallback
        begin
          JSON.parse(response.body)
        rescue => json_error
          Rails.logger.error "Manual JSON parse also failed: #{json_error.message}"
          nil
        end
      end
    else
      Rails.logger.error("Golf Course API Error: #{response.code} - #{response.message}")
      nil
    end
  end
end
