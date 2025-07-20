class Admin::MatchesController < Admin::BaseController
  before_action :set_tournament_and_round
  before_action :set_match, only: [ :show, :edit, :update, :destroy, :start, :complete, :cancel, :players, :add_player, :remove_player ]

  def index
    @matches = @round.matches.includes(:team_a, :team_b, :winner_team, :match_players, :players)
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
    @available_teams = @tournament.teams.order(:name)
  end

  def create
    @match = @round.matches.build(match_params)

    # Validate that golf course is selected
    if golf_course_missing?
      @match.errors.add(:golf_course_id, "must be selected")
    end

    if @match.errors.empty? && @match.save
      redirect_to scoped_admin_tournament_round_match_path(@tournament, @round, @match),
                  notice: "Match was successfully created with course: #{@match.golf_course_display}"
    else
      @available_teams = @tournament.teams.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_teams = @tournament.teams.order(:name)
  end

  def update
    # Validate that golf course is selected
    if golf_course_missing?
      @match.errors.add(:golf_course_id, "must be selected")
    end

    if @match.errors.empty? && @match.update(match_params)
      redirect_to scoped_admin_tournament_round_match_path(@tournament, @round, @match),
                  notice: "Match was successfully updated."
    else
      @available_teams = @tournament.teams.order(:name)
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

    begin
      service = GolfCourseApiService.new
      courses = service.search_courses(query)

      if courses&.any?
        formatted_courses = courses.map do |course|
          # Handle both integer and string IDs safely
          course_id = course["id"] || course[:id]
          course_name = course["course_name"] || course[:course_name]
          club_name = course["club_name"] || course[:club_name]
          location_data = course["location"] || course[:location]

          {
            id: course_id.to_s,  # Convert to string explicitly
            name: course_name,
            club_name: club_name,
            location: format_course_location(location_data)
          }
        end

        render json: { courses: formatted_courses }, status: :ok
      else
        render json: { courses: [] }, status: :ok
      end
    rescue => e
      Rails.logger.error "Golf Course API Error: #{e.message}"
      render json: { courses: [], error: "Unable to search courses at this time" }, status: :service_unavailable
    end
  end

  private

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
    params.require(:match).permit(:team_a_id, :team_b_id, :match_type, :scheduled_time, :golf_course_id, :golf_course_name, :golf_course_location)
  end

  def golf_course_missing?
    params.dig(:match, :golf_course_id).blank?
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
