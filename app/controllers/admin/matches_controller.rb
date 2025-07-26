class Admin::MatchesController < Admin::BaseController
  before_action :set_tournament_and_round
  before_action :set_match, only: [ :show, :edit, :update, :destroy, :start, :complete, :cancel, :players, :add_player, :remove_player ]

  def index
    @matches = @round.matches.includes(:winner_team, :match_players, :players, round: { tournament: [ :team_a, :team_b ] })
    @matches = @matches.where(match_type: params[:match_type]) if params[:match_type].present?
    @matches = @matches.where(status: params[:status]) if params[:status].present?
    @matches = @matches.order(:scheduled_time, :created_at)
  end

  def show
    @team_a_players = @match.team_a_players
    @team_b_players = @match.team_b_players
  end

  def new
    @match = @round.matches.build
  end

  def create
    @match = @round.matches.build(match_params)

    # Validate that golf course is selected
    if golf_course_missing?
      @match.errors.add(:base, "Golf course must be selected")
    end

    # Copy Course model data to holes_data JSON if Course is selected
    if @match.course_id.present?
      copy_course_data_to_match(@match)
    end

    if @match.errors.empty? && @match.save
      course_name = @match.course&.display_name || @match.golf_course_display
      redirect_to scoped_admin_tournament_round_match_path(@tournament, @round, @match),
                  notice: "Match was successfully created with course: #{course_name}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Validate that golf course is selected
    if golf_course_missing?
      @match.errors.add(:base, "Golf course must be selected")
    end

    # Check if course is being changed
    course_changed = match_params[:course_id] != @match.course_id.to_s

    if @match.errors.empty? && @match.update(match_params)
      # Copy Course model data to holes_data JSON if Course changed
      if course_changed && @match.course_id.present?
        copy_course_data_to_match(@match)
        @match.save! # Save the holes_data update
      end

      course_name = @match.course&.display_name || @match.golf_course_display
      redirect_to scoped_admin_tournament_round_match_path(@tournament, @round, @match),
                  notice: "Match was successfully updated with course: #{course_name}"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @match.destroy
    redirect_to scoped_admin_tournament_round_matches_path(@tournament, @round),
                notice: "Match was successfully deleted."
  end

  # Status transition actions
  def start
    @match.start!
    redirect_to scoped_admin_tournament_round_match_path(@tournament, @round, @match),
                notice: "Match has been started!"
  end

  def complete
    winner_team = Team.find(params[:winner_team_id]) if params[:winner_team_id].present?

    if winner_team && [ @match.team_a, @match.team_b ].include?(winner_team)
      @match.complete_with_winner!(winner_team)
      redirect_to scoped_admin_tournament_round_match_path(@tournament, @round, @match),
                  notice: "Match has been completed!"
    else
      redirect_to scoped_admin_tournament_round_match_path(@tournament, @round, @match),
                  alert: "Please select a valid winner team."
    end
  end

  def cancel
    @match.cancel!
    redirect_to scoped_admin_tournament_round_match_path(@tournament, @round, @match),
                notice: "Match has been cancelled."
  end

  # Player management actions
  def players
    @team_a_available_players = @match.team_a.players - @match.team_a_players
    @team_b_available_players = @match.team_b.players - @match.team_b_players
    @expected_players_per_team = @match.players_per_team
  end

  def add_player
    team = Team.find(params[:team_id])
    user = User.find(params[:user_id])

    # Validate team is part of match
    unless [ @match.team_a, @match.team_b ].include?(team)
      redirect_to scoped_players_admin_tournament_round_match_path(@tournament, @round, @match),
                  alert: "Invalid team selected."
      return
    end

    # Validate player has handicap for handicap-based match types
    if requires_handicap?(@match.match_type) && user.handicap.blank?
      redirect_to scoped_players_admin_tournament_round_match_path(@tournament, @round, @match),
                  alert: "#{user.display_name} must have a handicap set before joining #{@match.match_type.humanize} matches."
      return
    end

    match_player = @match.match_players.build(team: team, user: user)

    if match_player.save
      redirect_to scoped_players_admin_tournament_round_match_path(@tournament, @round, @match),
                  notice: "Player was successfully added to the match."
    else
      @team_a_available_players = @match.team_a.players - @match.team_a_players
      @team_b_available_players = @match.team_b.players - @match.team_b_players
      @expected_players_per_team = @match.players_per_team
      @error_message = match_player.errors.full_messages.join(", ")
      render :players, status: :unprocessable_entity
    end
  end

  def remove_player
    if params[:match_player_id].present?
      match_player = @match.match_players.find(params[:match_player_id])
    elsif params[:player_id].present?
      match_player = @match.match_players.find_by(user_id: params[:player_id])
    else
      redirect_to scoped_players_admin_tournament_round_match_path(@tournament, @round, @match),
                  alert: "No player specified for removal."
      return
    end

    if match_player&.destroy
      redirect_to scoped_players_admin_tournament_round_match_path(@tournament, @round, @match),
                  notice: "Player was successfully removed from the match."
    else
      redirect_to scoped_players_admin_tournament_round_match_path(@tournament, @round, @match),
                  alert: "Could not remove player from the match."
    end
  end

  def search_courses
    query = params[:q]

    if query.blank? || query.length < 3
      render json: { error: "Search query must be at least 3 characters" }, status: :unprocessable_entity
      return
    end

    all_courses = []

    # First, search local courses
    local_courses = Course.search(query).limit(10)
    all_courses += local_courses.map do |course|
      {
        id: "local_#{course.id}",
        name: course.name,
        club_name: course.club_name,
        location: course.location_display,
        source: "local"
      }
    end

    # Then search API courses (with error handling)
    begin
      service = GolfCourseApiService.new
      api_courses = service.search_courses(query) || []

      api_courses.each do |course|
        # Skip if we already have this course locally
        api_course_id = (course["id"] || course[:id]).to_s
        next if Course.exists?(api_course_id: api_course_id)

        course_name = course["course_name"] || course[:course_name]
        club_name = course["club_name"] || course[:club_name]
        location_data = course["location"] || course[:location]

        all_courses << {
          id: "api_#{api_course_id}",
          name: course_name,
          club_name: club_name,
          location: format_course_location(location_data),
          source: "api"
        }
      end
    rescue => e
      Rails.logger.error "Golf Course API Error: #{e.message}"
      # Continue with local results only
    end

    # Sort courses: local first, then by name
    sorted_courses = all_courses.sort_by { |course| [course[:source] == "local" ? 0 : 1, course[:name]] }

    render json: { 
      courses: sorted_courses.first(20), # Limit total results
      has_local_courses: local_courses.any?,
      api_available: all_courses.any? { |c| c[:source] == "api" }
    }, status: :ok
  end

  # POST /admin/groups/:group_slug/tournaments/:tournament_id/rounds/:round_id/matches/create_course
  def create_course
    course_params = params.require(:course)
    
    begin
      course = Course.new(
        name: course_params[:name],
        club_name: course_params[:club_name],
        address: course_params[:address],
        city: course_params[:city],
        state: course_params[:state],
        country: course_params[:country] || 'United States'
      )

      if course.save
        # Create tees if provided
        if course_params[:tees].present?
          course_params[:tees].each do |tee_data|
            next unless tee_data[:tee_name].present?

            tee = course.course_tees.create!(
              tee_name: tee_data[:tee_name],
              gender: tee_data[:gender],
              course_rating: tee_data[:course_rating],
              slope_rating: tee_data[:slope_rating],
              total_yards: tee_data[:total_yards],
              total_meters: tee_data[:total_meters] || (tee_data[:total_yards].to_i * 0.9144).round,
              par_total: tee_data[:par_total] || 72
            )

            # Create holes if provided
            if tee_data[:holes].present?
              tee_data[:holes].each_with_index do |hole_data, index|
                tee.course_holes.create!(
                  hole_number: index + 1,
                  par: hole_data[:par],
                  yardage: hole_data[:yardage],
                  handicap: hole_data[:handicap]
                )
              end
              
              # Recalculate totals based on actual hole data
              tee.recalculate_totals!
            end
          end
        end

        render json: { 
          success: true, 
          course: {
            id: course.id,
            name: course.name,
            club_name: course.club_name,
            location: course.location_display,
            source: "local"
          }
        }, status: :created
      else
        render json: { 
          success: false, 
          errors: course.errors.full_messages 
        }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Failed to create course: #{e.class}: #{e.message}"
      render json: { 
        success: false, 
        error: "Failed to create course: #{e.message}" 
      }, status: :internal_server_error
    end
  end

  # POST /admin/groups/:group_slug/tournaments/:tournament_id/rounds/:round_id/matches/select_course
  def select_course
    course_source = params[:course_source] # "local" or "api"
    course_identifier = params[:course_id]

    begin
      if course_source == "local"
        # Select existing local course
        course_id = course_identifier.sub("local_", "").to_i
        course = Course.find(course_id)
        
        render json: {
          success: true,
          course: {
            id: course.id,
            name: course.name,
            club_name: course.club_name,
            location: course.location_display,
            source: "local",
            use_course_model: true
          }
        }
      elsif course_source == "api"
        # Create local course from API data
        api_course_id = course_identifier.sub("api_", "")
        
        service = GolfCourseApiService.new
        api_data = service.get_course_details(api_course_id)
        
        if api_data
          course = Course.create_from_api_data(api_data, api_course_id)
          
          render json: {
            success: true,
            course: {
              id: course.id,
              name: course.name,
              club_name: course.club_name,
              location: course.location_display,
              source: "local", # Now it's local since we saved it
              use_course_model: true
            }
          }
        else
          render json: { success: false, error: "Unable to fetch course details from API" }, status: :unprocessable_entity
        end
      else
        render json: { success: false, error: "Invalid course source" }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, error: "Course not found" }, status: :not_found
    rescue => e
      Rails.logger.error "Failed to select course: #{e.class}: #{e.message}"
      render json: { success: false, error: "Failed to select course" }, status: :internal_server_error
    end
  end

  private

  def requires_handicap?(match_type)
    # Most match play formats require handicaps for fair stroke allocation
    %w[fourball_match_play singles_match_play scramble_match_play stableford_match_play].include?(match_type)
  end

  def copy_course_data_to_match(match)
    return unless match.course.present?

    begin
      # Convert Course model to API-compatible format and store in holes_data
      course_data = match.course.to_api_format
      
      # Clear any existing golf_course fields since we're using Course model
      match.golf_course_id = nil
      match.golf_course_name = match.course.name
      match.golf_course_location = match.course.location_display
      
      # Store the course data in holes_data for scoring compatibility
      match.holes_data = { "course_data" => course_data }
      
      Rails.logger.info "Copied Course model data to holes_data for match #{match.id}"
    rescue => e
      Rails.logger.error "Failed to copy course data to match: #{e.class}: #{e.message}"
      match.errors.add(:base, "Failed to load course data")
    end
  end

  def set_tournament_and_round
    @tournament = current_group.tournaments.find(params[:tournament_id])
    @round = @tournament.rounds.find(params[:round_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to scoped_admin_tournaments_path,
                alert: "Tournament or round not found in #{current_group.name}."
  end

  def set_match
    @match = @round.matches.find(params[:id])
  end

  def match_params
    permitted_params = params.require(:match).permit(:match_type, :scheduled_time, :golf_course_id, :golf_course_name, :golf_course_location, :course_id)
    
    # Convert empty strings to nil for foreign key fields to prevent constraint violations
    permitted_params[:course_id] = nil if permitted_params[:course_id].blank?
    permitted_params[:golf_course_id] = nil if permitted_params[:golf_course_id].blank?
    
    permitted_params
  end

  def golf_course_missing?
    # Check if either new Course model or legacy golf_course_id is present
    course_id = params.dig(:match, :course_id)
    golf_course_id = params.dig(:match, :golf_course_id)
    
    course_id.blank? && golf_course_id.blank?
  end

  def format_course_location(location_data)
    return "Location unavailable" unless location_data.present?

    begin
      if location_data.is_a?(Hash)
        city = location_data["city"] || location_data[:city]
        state = location_data["state"] || location_data[:state]

        if city && state
          "#{city}, #{state}"
        else
          location_data["address"] || location_data[:address] || "Location details unavailable"
        end
      else
        location_data.to_s
      end
    rescue => e
      Rails.logger.error "Error formatting location: #{e.message}"
      "Location unavailable"
    end
  end
end
