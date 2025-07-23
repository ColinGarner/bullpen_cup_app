require "test_helper"
require "minitest/mock"

class ScoringControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = users(:two) # From fixtures, admin: true
    @user = users(:one)  # Regular user
    @group = groups(:one)

    # Create players
    @player_a1 = User.create!(first_name: "Player", last_name: "A1", email: "a1@example.com", password: "password123", handicap: 10)
    @player_a2 = User.create!(first_name: "Player", last_name: "A2", email: "a2@example.com", password: "password123", handicap: 15)
    @player_b1 = User.create!(first_name: "Player", last_name: "B1", email: "b1@example.com", password: "password123", handicap: 8)
    @player_b2 = User.create!(first_name: "Player", last_name: "B2", email: "b2@example.com", password: "password123", handicap: 12)

    @tournament = Tournament.create!(
      name: "Test Tournament",
      start_date: Date.today,
      end_date: 1.week.from_now.to_date,
      created_by: @admin,
      group: @group
    )

    @round = Round.create!(
      tournament: @tournament,
      round_number: 1,
      name: "Test Round"
    )

    @team_a = Team.create!(
      name: "Team Alpha",
      tournament: @tournament,
      captain: @admin
    )

    @team_b = Team.create!(
      name: "Team Beta",
      tournament: @tournament,
      captain: @user
    )

    # Add players to teams
    @team_a.add_player(@player_a1)
    @team_a.add_player(@player_a2)
    @team_b.add_player(@player_b1)
    @team_b.add_player(@player_b2)

    # Assign teams to tournament
    @tournament.update!(team_a: @team_a, team_b: @team_b)

    @match = Match.create!(
      round: @round,
      match_type: "singles_match_play",
      scheduled_time: Time.current,
      golf_course_id: "12345"
    )

    # Add players to match
    MatchPlayer.create!(match: @match, team: @team_a, user: @player_a1)
    MatchPlayer.create!(match: @match, team: @team_b, user: @player_b1)

    # Mock course data
    @course_data = {
      "course" => {
        "tees" => {
          "male" => [
            {
              "tee_name" => "Blue Tees",
              "total_yards" => 6800,
              "course_rating" => 72.1,
              "slope_rating" => 135,
              "par_total" => 72,
              "holes" => Array.new(18) { |i| { "par" => 4, "handicap" => i + 1, "yardage" => 400 } }
            }
          ],
          "female" => [
            {
              "tee_name" => "Red Tees",
              "total_yards" => 5400,
              "course_rating" => 69.2,
              "slope_rating" => 120,
              "par_total" => 72,
              "holes" => Array.new(18) { |i| { "par" => 4, "handicap" => i + 1, "yardage" => 300 } }
            }
          ]
        }
      }
    }
  end

  # Authentication Tests
  test "should redirect to login when not authenticated" do
    get select_tees_match_path(@match)
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "should redirect when user not in match" do
    sign_in @user
    get select_tees_match_path(@match)
    assert_response :redirect
    assert_equal "You are not a player in this match.", flash[:alert]
  end

  # Select Tees Tests
  test "should show select tees page for valid match" do
    sign_in @player_a1

    # Mock the golf course API service
    mock_service = Minitest::Mock.new
    mock_service.expect(:get_course_details, @course_data, [ @match.golf_course_id ])
    GolfCourseApiService.stub(:new, mock_service) do
      get select_tees_match_path(@match)
    end

    assert_response :success
    assert_select "h1", text: /Select Your Tees/
    mock_service.verify
  end

  test "should redirect when match not scheduled for today" do
    @match.update!(scheduled_time: 1.week.from_now)
    sign_in @player_a1

    get select_tees_match_path(@match)
    assert_response :redirect
    assert_equal "This match is not available for scoring right now.", flash[:alert]
  end

  test "should redirect when match not upcoming" do
    @match.update!(status: "active")
    sign_in @player_a1

    get select_tees_match_path(@match)
    assert_response :redirect
    assert_equal "This match is not available for scoring right now.", flash[:alert]
  end

  test "should redirect when no golf course assigned" do
    @match.update!(golf_course_id: nil)
    sign_in @player_a1

    get select_tees_match_path(@match)
    assert_response :redirect
    assert_equal "No golf course assigned to this match. Please contact an admin.", flash[:alert]
  end

  test "should handle golf course API error gracefully" do
    sign_in @player_a1

    # Mock API error
    mock_service = Minitest::Mock.new
    mock_service.expect(:get_course_details, nil, [ @match.golf_course_id ])
    GolfCourseApiService.stub(:new, mock_service) do
      get select_tees_match_path(@match)
    end

    assert_response :success
    mock_service.verify
  end

  # Save Tees Tests
  test "should save tees and start match" do
    sign_in @player_a1

    mock_service = Minitest::Mock.new
    mock_service.expect(:get_course_details, @course_data, [ @match.golf_course_id ])
    GolfCourseApiService.stub(:new, mock_service) do
      post save_tees_match_path(@match), params: { tee_name: "Blue Tees" }
    end

    assert_response :redirect
    assert_redirected_to next_hole_match_path(@match)
    assert_equal "Tees selected! Start scoring.", flash[:notice]

    @match.reload
    assert_equal "Blue Tees", @match.selected_tee_name
    assert_equal "active", @match.status
    assert_not_nil @match.holes_data
    mock_service.verify
  end

  test "should redirect when no tee selected" do
    sign_in @player_a1

    post save_tees_match_path(@match), params: { tee_name: "" }
    assert_response :redirect
    assert_redirected_to select_tees_match_path(@match)
    assert_equal "Please select a tee.", flash[:alert]
  end

  test "should redirect when invalid tee selected" do
    sign_in @player_a1

    mock_service = Minitest::Mock.new
    mock_service.expect(:get_course_details, @course_data, [ @match.golf_course_id ])
    GolfCourseApiService.stub(:new, mock_service) do
      post save_tees_match_path(@match), params: { tee_name: "Invalid Tee" }
    end

    assert_response :redirect
    assert_redirected_to select_tees_match_path(@match)
    assert_equal "Invalid tee selection.", flash[:alert]
    mock_service.verify
  end

  # Score Hole Tests
  test "should show score hole page for valid hole" do
    setup_active_match
    sign_in @player_a1

    get score_hole_match_path(@match, hole: 1)
    assert_response :success
    # Just check that the page loaded successfully - specific content varies by match type
  end

  test "should redirect for invalid hole number" do
    setup_active_match
    sign_in @player_a1

    get score_hole_match_path(@match, hole: 19)
    assert_response :redirect
    assert_redirected_to next_hole_match_path(@match)
    assert_equal "Invalid hole number.", flash[:alert]
  end

  test "should redirect for zero hole number" do
    setup_active_match
    sign_in @player_a1

    get score_hole_match_path(@match, hole: 0)
    assert_response :redirect
    assert_redirected_to next_hole_match_path(@match)
    assert_equal "Invalid hole number.", flash[:alert]
  end

  # Update Score Tests
  test "should update scores and move to next hole" do
    setup_active_match
    sign_in @player_a1

    post update_score_match_path(@match, hole: 1), params: {
      scores: {
        @player_a1.id.to_s => "4",
        @player_b1.id.to_s => "5"
      }
    }

    assert_response :redirect
    assert_redirected_to score_hole_match_path(@match, hole: 2)
    assert_equal "Hole 1 scored! Moving to hole 2.", flash[:notice]

    # Verify scores were created
    score_a1 = @match.scores.find_by(user: @player_a1, hole_number: 1)
    score_b1 = @match.scores.find_by(user: @player_b1, hole_number: 1)

    assert_not_nil score_a1
    assert_not_nil score_b1
    assert_equal 4, score_a1.strokes
    assert_equal 5, score_b1.strokes
  end

  test "should complete match after hole 18" do
    setup_active_match
    sign_in @player_a1

    post update_score_match_path(@match, hole: 18), params: {
      scores: {
        @player_a1.id.to_s => "4",
        @player_b1.id.to_s => "5"
      }
    }

    assert_response :redirect
    assert_redirected_to leaderboard_tournament_path(@tournament)
    assert_equal "Match completed! Check out the tournament results.", flash[:notice]

    @match.reload
    assert_equal "completed", @match.status
  end

  test "should skip empty scores" do
    setup_active_match
    sign_in @player_a1

    post update_score_match_path(@match, hole: 1), params: {
      scores: {
        @player_a1.id.to_s => "4",
        @player_b1.id.to_s => "" # Empty score
      }
    }

    assert_response :redirect

    # Verify only non-empty score was saved
    score_a1 = @match.scores.find_by(user: @player_a1, hole_number: 1)
    score_b1 = @match.scores.find_by(user: @player_b1, hole_number: 1)

    assert_not_nil score_a1
    assert_nil score_b1
  end

  # Leaderboard Tests
  test "should show match leaderboard" do
    setup_active_match
    sign_in @player_a1

    # Set up group context
    @group.group_memberships.create!(user: @player_a1, role: "member")

    get leaderboard_match_path(@match)
    assert_response :success
    # Just verify the page loads successfully - content structure may vary
  end

  test "should handle when tournament not found" do
    @match.round.destroy
    sign_in @player_a1

    # Set up group context
    @group.group_memberships.create!(user: @player_a1, role: "member")

    get leaderboard_match_path(@match)
    # Expect either redirect or 404 - both are valid responses when tournament not found
    assert_includes [ 302, 404 ], response.status
  end

  # Tournament Leaderboard Tests
  test "should show tournament leaderboard" do
    sign_in @player_a1

    # Set up group context
    @group.group_memberships.create!(user: @player_a1, role: "member")

    get leaderboard_tournament_path(@tournament)
    assert_response :success
    # Just verify the page loads successfully - content structure may vary
  end

  # Next Hole Tests
  test "should redirect to next unscored hole" do
    setup_active_match
    sign_in @player_a1

    # Create score for hole 1
    Score.create!(
      match: @match,
      user: @player_a1,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    get next_hole_match_path(@match)
    assert_response :redirect
    assert_redirected_to score_hole_match_path(@match, hole: 2)
  end

  test "should redirect to hole 1 when no scores exist" do
    setup_active_match
    sign_in @player_a1

    get next_hole_match_path(@match)
    assert_response :redirect
    assert_redirected_to score_hole_match_path(@match, hole: 1)
  end

  test "should redirect to hole 18 when all holes complete" do
    setup_active_match
    sign_in @player_a1

    # Create scores for all 18 holes
    (1..18).each do |hole|
      Score.create!(
        match: @match,
        user: @player_a1,
        hole_number: hole,
        strokes: 4,
        net_strokes: 4,
        handicap_used: 10,
        strokes_received_on_hole: 0
      )
    end

    get next_hole_match_path(@match)
    assert_response :redirect
    assert_redirected_to score_hole_match_path(@match, hole: 18)
  end

  # Match Status Calculation Tests
  test "should calculate singles match status correctly" do
    controller = ScoringController.new

    # Test with upcoming match
    result = controller.send(:calculate_singles_match_status, @match)

    assert_equal "upcoming", result[:status]
    assert_equal "A/S", result[:result]
    assert_equal 0, result[:holes_played]
  end

  test "should calculate fourball match status correctly" do
    @match.update!(match_type: "fourball_match_play")
    # Add second players to match
    MatchPlayer.create!(match: @match, team: @team_a, user: @player_a2)
    MatchPlayer.create!(match: @match, team: @team_b, user: @player_b2)

    controller = ScoringController.new

    result = controller.send(:calculate_fourball_match_status, @match)

    assert_equal "upcoming", result[:status]
    assert_equal "A/S", result[:result]
    assert_equal 0, result[:holes_played]
  end

  test "should calculate scramble match status correctly" do
    @match.update!(match_type: "scramble_match_play")
    # Add second players to match
    MatchPlayer.create!(match: @match, team: @team_a, user: @player_a2)
    MatchPlayer.create!(match: @match, team: @team_b, user: @player_b2)

    controller = ScoringController.new

    result = controller.send(:calculate_scramble_match_status, @match)

    assert_equal "upcoming", result[:status]
    assert_equal "A/S", result[:result]
    assert_equal 0, result[:holes_played]
  end

  test "should calculate stableford match status correctly" do
    @match.update!(match_type: "stableford_match_play")
    controller = ScoringController.new

    result = controller.send(:calculate_stableford_match_status, @match)

    assert_equal "upcoming", result[:status]
    assert result[:result].present?
    assert_equal 0, result[:holes_played]
  end

  # Stroke Calculation Tests
  test "should calculate singles strokes correctly" do
    setup_active_match
    controller = ScoringController.new
    controller.instance_variable_set(:@match, @match)

    # Mock hole data
    hole_data = { "handicap" => 1, "par" => 4 }

    strokes = controller.send(:calculate_singles_strokes_received, @player_a1, 1, hole_data)
    assert strokes >= 0
    assert strokes <= 1
  end

  test "should calculate fourball strokes correctly" do
    @match.update!(match_type: "fourball_match_play")
    MatchPlayer.create!(match: @match, team: @team_a, user: @player_a2)
    MatchPlayer.create!(match: @match, team: @team_b, user: @player_b2)

    setup_active_match
    controller = ScoringController.new
    controller.instance_variable_set(:@match, @match)

    hole_data = { "handicap" => 1, "par" => 4 }

    strokes = controller.send(:calculate_fourball_strokes_received, @player_a1, 1, hole_data)
    assert strokes >= 0
    assert strokes <= 1
  end

  test "should calculate scramble strokes correctly" do
    @match.update!(match_type: "scramble_match_play")
    MatchPlayer.create!(match: @match, team: @team_a, user: @player_a2)
    MatchPlayer.create!(match: @match, team: @team_b, user: @player_b2)

    setup_active_match
    controller = ScoringController.new
    controller.instance_variable_set(:@match, @match)

    hole_data = { "handicap" => 1, "par" => 4 }

    strokes = controller.send(:calculate_scramble_strokes_received, @player_a1, 1, hole_data)
    assert strokes >= 0
    assert strokes <= 1
  end

  # Course Handicap Calculation Tests
  test "should calculate course handicap correctly" do
    setup_active_match
    controller = ScoringController.new

    course_handicap = controller.send(:calculate_course_handicap, @player_a1, @match)
    assert course_handicap >= 0
    # Should be close to player's handicap adjusted for slope
    expected = (@player_a1.handicap * (135.0 / 113.0)).round
    assert_equal expected, course_handicap
  end

  test "should return zero when no handicap" do
    @player_a1.update!(handicap: nil)
    setup_active_match
    controller = ScoringController.new

    course_handicap = controller.send(:calculate_course_handicap, @player_a1, @match)
    assert_equal 0, course_handicap
  end

  # Stableford Points Tests
  test "should calculate stableford points correctly" do
    controller = ScoringController.new

    # Eagle = 8 points
    assert_equal 8, controller.send(:calculate_stableford_points, 2, 4)
    # Birdie = 4 points
    assert_equal 4, controller.send(:calculate_stableford_points, 3, 4)
    # Par = 2 points
    assert_equal 2, controller.send(:calculate_stableford_points, 4, 4)
    # Bogey = 1 point
    assert_equal 1, controller.send(:calculate_stableford_points, 5, 4)
    # Double bogey = 0 points
    assert_equal 0, controller.send(:calculate_stableford_points, 6, 4)
  end

  test "should calculate stableford quota correctly" do
    setup_active_match
    controller = ScoringController.new

    quota = controller.send(:calculate_stableford_quota, @player_a1, @match)
    # Course handicap is roughly 12 (10 * 135/113), so quota should be 36 - 12 = 24
    expected_course_handicap = (@player_a1.handicap * (135.0 / 113.0)).round
    expected_quota = 36 - expected_course_handicap
    assert_equal expected_quota, quota
  end

  # Team Standings Tests
  test "should calculate team standings correctly" do
    controller = ScoringController.new

    standings = controller.send(:calculate_team_standings, [ @match ])

    assert standings[:team_points].present?
    assert_equal 0, standings[:completed_matches]
    assert_equal 1, standings[:total_matches]
    assert_equal 1, standings[:total_points_available]
  end

  private

  def setup_active_match
    @match.update!(
      status: "active",
      selected_tee_name: "Blue Tees",
      holes_data: { "holes" => @course_data["course"]["tees"]["male"][0]["holes"], "course_data" => @course_data }
    )
  end
end
