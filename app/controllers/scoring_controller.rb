class ScoringController < ApplicationController
  before_action :authenticate_user!
  before_action :set_match, only: [:select_tees, :save_tees, :score_hole, :update_score, :leaderboard, :next_hole]
  before_action :ensure_player_in_match, only: [:select_tees, :save_tees, :score_hole, :update_score, :next_hole]
  before_action :fetch_course_data, only: [:select_tees, :save_tees, :score_hole, :update_score]

  helper_method :calculate_total_match_strokes, :calculate_strokes_received

  # GET /matches/:id/select_tees
  def select_tees
    # Check if match is ready to start (scheduled for today and not yet active)
    unless @match.status == 'upcoming' && @match.scheduled_for_today?
      redirect_to root_path, alert: 'This match is not available for scoring right now.'
      return
    end

    # If tees already selected, allow re-selection for now (can remove this later)
    # This helps during development and testing

    # Check if match has golf course data
    unless @match.golf_course_id.present?
      redirect_to root_path, alert: 'No golf course assigned to this match. Please contact an admin.'
      return
    end

    @available_tees = extract_available_tees
  end

  # POST /matches/:id/save_tees
  def save_tees
    tee_name = params[:tee_name]
    
    unless tee_name.present?
      redirect_to select_tees_match_path(@match), alert: 'Please select a tee.'
      return
    end

    # Find the selected tee data
    selected_tee_data = find_tee_data(tee_name)
    
    unless selected_tee_data
      redirect_to select_tees_match_path(@match), alert: 'Invalid tee selection.'
      return
    end

    # Update match with selected tee and start scoring
    @match.update!(
      selected_tee_name: tee_name,
      holes_data: selected_tee_data,
      status: 'active'
    )

    redirect_to next_hole_match_path(@match), notice: 'Tees selected! Start scoring.'
  end

  # GET /matches/:id/score/hole/:hole
  def score_hole
    @hole_number = params[:hole].to_i
    
    unless (1..18).include?(@hole_number)
      redirect_to next_hole_match_path(@match), alert: 'Invalid hole number.'
      return
    end

    @hole_data = @match.holes_data['holes'][@hole_number - 1] if @match.holes_data
    @players = @match.players.includes(:scores)
    @scores = @match.scores.where(hole_number: @hole_number).includes(:user)
  end

  # POST /matches/:id/score/hole/:hole
  def update_score
    @hole_number = params[:hole].to_i
    player_scores = params[:scores] || {}

    player_scores.each do |user_id, strokes|
      next unless strokes.present? && strokes.to_i > 0

      player = User.find(user_id)
      strokes_received = calculate_strokes_received(player, @hole_number)
      
      # Only create/update score when user actually enters a score
      @match.scores.find_or_create_by(
        user_id: user_id,
        hole_number: @hole_number
      ) do |score|
        score.strokes = strokes.to_i
        score.net_strokes = [strokes.to_i - strokes_received, 1].max
        score.handicap_used = player.handicap || 0
        score.strokes_received_on_hole = strokes_received
      end.update!(
        strokes: strokes.to_i,
        net_strokes: [strokes.to_i - strokes_received, 1].max,
        handicap_used: player.handicap || 0,
        strokes_received_on_hole: strokes_received
      )
    end

    # Determine next hole or completion
    if @hole_number < 18
      redirect_to score_hole_match_path(@match, hole: @hole_number + 1), notice: "Hole #{@hole_number} scored! Moving to hole #{@hole_number + 1}."
    else
      # Match complete
      @match.update!(status: 'completed')
      redirect_to leaderboard_tournament_path(@match.round.tournament), notice: 'Match completed! Check out the tournament results.'
    end
  end

  # GET /matches/:id/leaderboard
  def leaderboard
    # Safely navigate to tournament
    @tournament = @match&.round&.tournament
    
    if @tournament.nil?
      redirect_to root_path, alert: "Tournament not found"
      return
    end
    
    @rounds = @tournament.rounds.includes(matches: [:team_a, :team_b, :players, :scores, :winner_team])
    
    # Get all matches in the tournament with their current status
    @tournament_matches = @rounds.flat_map(&:matches)
    
    # Calculate match results for each match - create a hash for easy lookup
    @match_results = {}
    @tournament_matches.each do |match|
      @match_results[match.id] = calculate_match_status(match)
    end
    
    # Calculate team standings
    @team_standings = calculate_team_standings(@tournament_matches)
    
    # Current match details (if viewing from a specific match)
    @current_match = @match
    @current_match_result = calculate_match_status(@match)
  end

  # GET /tournaments/:id/leaderboard
  def tournament_leaderboard
    @tournament = Tournament.find(params[:id])
    @rounds = @tournament.rounds.includes(matches: [:team_a, :team_b, :players, :scores, :winner_team])
    
    # Get all matches in the tournament with their current status
    @tournament_matches = @rounds.flat_map(&:matches)
    
    # Calculate match results for each match - create a hash for easy lookup
    @match_results = {}
    @tournament_matches.each do |match|
      @match_results[match.id] = calculate_match_status(match)
    end
    
    # Calculate team standings
    @team_standings = calculate_team_standings(@tournament_matches)
    
    # Find current user's active match for continue button
    @current_user_match = @tournament_matches.find { |m| m.status == 'active' && m.players.include?(current_user) }
    @current_match = nil
    @current_match_result = nil
    
    # Use the same view as match leaderboard
    render :leaderboard
  end

  # GET /matches/:id/next_hole - redirects to the next hole that needs scoring
  def next_hole
    next_hole_number = calculate_next_hole_for_user(current_user)
    redirect_to score_hole_match_path(@match, hole: next_hole_number)
  end

  private

  def calculate_next_hole_for_user(user)
    # Find the highest hole number this user has scored in this match
    last_scored_hole = @match.scores.where(user: user).where.not(strokes: 0).maximum(:hole_number) || 0
    
    # If all holes are complete, go to hole 18 to view/edit
    return 18 if last_scored_hole >= 18
    
    # Return the next hole that needs scoring
    last_scored_hole + 1
  end

  def set_match
    @match = Match.find(params[:id] || params[:match_id])
  end

  def ensure_player_in_match
    unless @match.players.include?(current_user)
      redirect_to root_path, alert: 'You are not a player in this match.'
    end
  end

  def fetch_course_data
    return if @match.golf_course_id.blank?

    begin
      service = GolfCourseApiService.new
      @course_data = service.get_course_details(@match.golf_course_id)
      
      if @course_data.nil?
        Rails.logger.error "Golf Course API returned nil for course ID: #{@match.golf_course_id}"
        @api_error = "Unable to load course information from API. Using default tee options."
      end
      
    rescue => e
      Rails.logger.error "Failed to fetch course data: #{e.class}: #{e.message}"
      Rails.logger.error "Course ID: #{@match.golf_course_id}"
      @api_error = "Course API unavailable: #{e.message}. Using default tee options."
    end
  end

  def extract_available_tees
    return [] unless @course_data&.dig('course', 'tees')

    tees = []
    @course_data['course']['tees'].each do |gender, gender_tees|
      gender_tees.each do |tee|
        tees << {
          name: tee['tee_name'],
          gender: gender,
          yardage: tee['total_yards'],
          rating: tee['course_rating'],
          slope: tee['slope_rating'],
          par: tee['par_total']
        }
      end
    end
    
    tees.sort_by { |tee| -tee[:yardage] } # Sort by yardage, longest first
  end

  def find_tee_data(tee_name)
    return nil unless @course_data&.dig('course', 'tees')

    @course_data['course']['tees'].each do |gender, gender_tees|
      gender_tees.each do |tee|
        return tee if tee['tee_name'] == tee_name
      end
    end
    
    nil
  end

  def calculate_match_status(match)
    return { status: 'upcoming', result: 'Not Started', description: '', player1: nil, player2: nil, holes_played: 0 } if match.status == 'upcoming'
    
    # Handle different match types
    case match.match_type
    when 'singles_match_play'
      calculate_singles_match_status(match)
    when 'fourball_match_play'
      calculate_fourball_match_status(match)
    else
      calculate_singles_match_status(match) # Default to singles for now
    end
  end

  def calculate_singles_match_status(match)
    # Safely get players
    players = match.players rescue []
    return { status: 'no_players', result: 'No Players', description: '', player1: nil, player2: nil, holes_played: 0 } if players.count != 2
    
    player1, player2 = players.to_a
    
    # Safely get scores
    match_scores = match.scores rescue []
    scores_by_player = match_scores.group_by(&:user_id)
    
    player1_scores = scores_by_player[player1.id] || []
    player2_scores = scores_by_player[player2.id] || []
    
    # Get scores by hole for both players
    player1_holes = player1_scores.index_by(&:hole_number)
    player2_holes = player2_scores.index_by(&:hole_number)
    
    # Calculate match play status
    holes_ahead = 0
    holes_played = 0
    
    (1..18).each do |hole|
      p1_score = player1_holes[hole]
      p2_score = player2_holes[hole]
      
      if p1_score&.net_strokes&.positive? && p2_score&.net_strokes&.positive?
        holes_played += 1
        if p1_score.net_strokes < p2_score.net_strokes
          holes_ahead += 1  # Player 1 wins hole
        elsif p2_score.net_strokes < p1_score.net_strokes
          holes_ahead -= 1  # Player 2 wins hole
        end
        # Tie = no change to holes_ahead
      end
    end
    
    holes_remaining = 18 - holes_played
    leader = holes_ahead > 0 ? player1 : (holes_ahead < 0 ? player2 : nil)
    holes_ahead_abs = holes_ahead.abs
    
    # Determine match result
    if match.status == 'completed'
      if holes_ahead == 0
        result = 'A/S'  # All Square
        description = 'Match tied'
      else
        if holes_ahead_abs > holes_remaining
          # Match won before 18th hole
          holes_won_by = holes_ahead_abs - holes_remaining
          result = "#{holes_won_by}&#{holes_remaining + 1}"
        else
          # Match went to 18th hole or beyond
          result = "#{holes_ahead_abs}UP"
        end
        description = "#{leader.display_name} wins"
      end
      status = 'completed'
    else
      # Match in progress
      if holes_ahead == 0
        result = 'A/S'
        description = holes_played > 0 ? 'All Square' : 'Not Started'
      else
        if holes_ahead_abs > holes_remaining
          # Match can be won
          result = "#{holes_ahead_abs}UP"
          description = "#{leader.display_name} dormie"
        else
          result = "#{holes_ahead_abs}UP"
          description = "#{leader.display_name} leads"
        end
      end
      status = holes_played > 0 ? 'active' : 'upcoming'
    end
    
    {
      status: status,
      result: result,
      description: description,
      leader: leader,
      holes_ahead: holes_ahead,
      holes_played: holes_played,
      player1: player1,
      player2: player2
    }
  end

  def calculate_fourball_match_status(match)
    # Safely get players grouped by team
    team_a_players = match.players_for_team(match.team_a) rescue []
    team_b_players = match.players_for_team(match.team_b) rescue []
    
    return { status: 'no_players', result: 'No Players', description: '', player1: nil, player2: nil, holes_played: 0 } if team_a_players.empty? || team_b_players.empty?
    
    # Get all scores for the match
    match_scores = match.scores rescue []
    scores_by_player = match_scores.group_by(&:user_id)
    
    # Calculate team scores for each hole
    holes_ahead = 0
    holes_played = 0
    
    (1..18).each do |hole|
      # Get scores for team A players on this hole
      team_a_scores = team_a_players.map do |player|
        scores_by_player[player.id]&.find { |s| s.hole_number == hole && s.net_strokes&.positive? }&.net_strokes
      end.compact
      
      # Get scores for team B players on this hole
      team_b_scores = team_b_players.map do |player|
        scores_by_player[player.id]&.find { |s| s.hole_number == hole && s.net_strokes&.positive? }&.net_strokes
      end.compact
      
      # Only count holes where at least one player from each team has a score
      if team_a_scores.any? && team_b_scores.any?
        holes_played += 1
        
        # Get the best (lowest) score for each team
        team_a_best = team_a_scores.min
        team_b_best = team_b_scores.min
        
        # Determine hole winner
        if team_a_best < team_b_best
          holes_ahead += 1  # Team A wins hole
        elsif team_b_best < team_a_best
          holes_ahead -= 1  # Team B wins hole
        end
        # Tie = no change to holes_ahead
      end
    end
    
    holes_remaining = 18 - holes_played
    leader_team = holes_ahead > 0 ? match.team_a : (holes_ahead < 0 ? match.team_b : nil)
    holes_ahead_abs = holes_ahead.abs
    
    # For display purposes, we'll use team representatives as player1/player2
    team_a_rep = team_a_players.first
    team_b_rep = team_b_players.first
    leader = holes_ahead > 0 ? team_a_rep : (holes_ahead < 0 ? team_b_rep : nil)
    
    # Determine match result
    if match.status == 'completed'
      if holes_ahead == 0
        result = 'A/S'  # All Square
        description = 'Match tied'
      else
        if holes_ahead_abs > holes_remaining
          # Match won before 18th hole
          holes_won_by = holes_ahead_abs - holes_remaining
          result = "#{holes_won_by}&#{holes_remaining + 1}"
        else
          # Match went to 18th hole or beyond
          result = "#{holes_ahead_abs}UP"
        end
        description = "#{leader_team.name} wins"
      end
      status = 'completed'
    else
      # Match in progress
      if holes_ahead == 0
        result = 'A/S'
        description = holes_played > 0 ? 'All Square' : 'Not Started'
      else
        if holes_ahead_abs > holes_remaining
          # Match can be won
          result = "#{holes_ahead_abs}UP"
          description = "#{leader_team.name} dormie"
        else
          result = "#{holes_ahead_abs}UP"
          description = "#{leader_team.name} leads"
        end
      end
      status = holes_played > 0 ? 'active' : 'upcoming'
    end
    
    {
      status: status,
      result: result,
      description: description,
      leader: leader,
      leader_team: leader_team,
      holes_ahead: holes_ahead,
      holes_played: holes_played,
      player1: team_a_rep,
      player2: team_b_rep,
      team_a_players: team_a_players,
      team_b_players: team_b_players
    }
  end

  def calculate_team_standings(matches)
    team_points = Hash.new(0.0)
    completed_matches = 0
    total_points_available = 0
    
    # First, ensure all teams appear in standings with 0 points
    matches.each do |match|
      team_points[match.team_a.name] = 0.0 unless team_points.key?(match.team_a.name)
      team_points[match.team_b.name] = 0.0 unless team_points.key?(match.team_b.name)
    end
    
    matches.each do |match|
      total_points_available += 1
      
      next unless match.status == 'completed'
      
      completed_matches += 1
      
      # Calculate match result
      match_result = calculate_match_status(match)
      
      if match_result[:leader].nil?
        # Tie - each team gets 0.5 points
        team_points[match.team_a.name] += 0.5
        team_points[match.team_b.name] += 0.5
      else
        # Win/Loss - winner gets 1 point, loser gets 0
        if match_result[:leader] == match_result[:player1]
          team_points[match.team_a.name] += 1.0
        else
          team_points[match.team_b.name] += 1.0
        end
      end
    end
    
    {
      team_points: team_points.sort_by { |name, points| -points }.to_h,
      completed_matches: completed_matches,
      total_matches: matches.count,
      total_points_available: total_points_available
    }
  end

  def calculate_strokes_received(player, hole_number)
    return 0 unless player.handicap && @match.holes_data

    hole_data = @match.holes_data['holes'][hole_number - 1]
    return 0 unless hole_data

    case @match.match_type
    when 'fourball_match_play'
      calculate_fourball_strokes_received(player, hole_number, hole_data)
    when 'singles_match_play'
      calculate_singles_strokes_received(player, hole_number, hole_data)
    else
      calculate_singles_strokes_received(player, hole_number, hole_data) # Default to singles
    end
  end

  private

  def calculate_singles_strokes_received(player, hole_number, hole_data)
    # Get both players in the match
    players = @match.players.to_a
    return 0 unless players.count == 2

    # Find the other player
    other_player = players.find { |p| p != player }
    return 0 unless other_player&.handicap

    # Calculate course handicaps for both players
    player_course_handicap = calculate_course_handicap(player)
    other_course_handicap = calculate_course_handicap(other_player)

    # Calculate stroke difference (lower handicap plays off scratch)
    stroke_difference = (player_course_handicap - other_course_handicap).round

    # If this player has the lower handicap (negative difference), they get 0 strokes
    return 0 if stroke_difference <= 0

    # This player gets strokes equal to the difference
    # Strokes are allocated to holes based on hole handicap ranking
    hole_handicap = hole_data['handicap']

    # Player gets a stroke on this hole if the hole handicap is <= the stroke difference
    hole_handicap <= stroke_difference ? 1 : 0
  end

  def calculate_fourball_strokes_received(player, hole_number, hole_data)
    # Get players from both teams
    team_a_players = @match.players_for_team(@match.team_a)
    team_b_players = @match.players_for_team(@match.team_b)
    
    return 0 if team_a_players.empty? || team_b_players.empty?

    # Get all players in the match
    all_players = team_a_players + team_b_players
    
    # Find the overall low man (lowest course handicap from all 4 players)
    low_man = all_players.min_by { |p| calculate_course_handicap(p) }
    return 0 unless low_man&.handicap

    # Calculate course handicaps
    player_course_handicap = calculate_course_handicap(player)
    low_man_course_handicap = calculate_course_handicap(low_man)

    # Calculate stroke difference from the low man
    stroke_difference = (player_course_handicap - low_man_course_handicap).round
    
    # No negative strokes
    return 0 if stroke_difference <= 0

    # Strokes are allocated to holes based on hole handicap ranking
    hole_handicap = hole_data['handicap']

    # Player gets a stroke on this hole if the hole handicap is <= their stroke difference
    hole_handicap <= stroke_difference ? 1 : 0
  end

  def calculate_course_handicap(player)
    return 0 unless player.handicap && @match.selected_tee_name

    # Get the tee data from course data based on selected tee name
    tee_data = find_tee_data(@match.selected_tee_name)
    return 0 unless tee_data

    # Course Handicap = Handicap Index × (Slope Rating ÷ 113) + (Course Rating - Par)
    # For simplicity, we'll use: Handicap Index × (Slope Rating ÷ 113)
    slope_rating = tee_data['slope_rating'] || 113
    (player.handicap.to_f * (slope_rating / 113.0)).round
  end

  # Helper method to calculate total strokes a player receives for the entire match
  def calculate_total_match_strokes(player)
    return 0 unless player.handicap

    case @match.match_type
    when 'fourball_match_play'
      # Get all players in the match
      team_a_players = @match.players_for_team(@match.team_a)
      team_b_players = @match.players_for_team(@match.team_b)
      all_players = team_a_players + team_b_players
      
      # Find the overall low man
      low_man = all_players.min_by { |p| calculate_course_handicap(p) }
      return 0 unless low_man&.handicap

      # Calculate stroke difference from the low man
      player_course_handicap = calculate_course_handicap(player)
      low_man_course_handicap = calculate_course_handicap(low_man)
      stroke_difference = (player_course_handicap - low_man_course_handicap).round
      
      [stroke_difference, 0].max
    when 'singles_match_play'
      # In singles, calculate against the other player
      players = @match.players.to_a
      return 0 unless players.count == 2

      other_player = players.find { |p| p != player }
      return 0 unless other_player&.handicap

      player_course_handicap = calculate_course_handicap(player)
      other_course_handicap = calculate_course_handicap(other_player)
      stroke_difference = (player_course_handicap - other_course_handicap).round
      
      [stroke_difference, 0].max
    else
      0
    end
  end


end
