require "test_helper"

class Admin::MatchesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:two) # From fixtures, admin: true
    @user = users(:one)  # Regular user
    @group = groups(:one)

    # Create a user with no admin privileges for testing
    @non_admin_user = User.create!(
      first_name: "Regular",
      last_name: "User",
      email: "regular@example.com",
      password: "password123",
      admin: false
    )

    @tournament = Tournament.create!(
      name: "Test Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
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
    @player_a1 = User.create!(first_name: "Player", last_name: "A1", email: "a1@example.com", password: "password123")
    @player_a2 = User.create!(first_name: "Player", last_name: "A2", email: "a2@example.com", password: "password123")
    @player_b1 = User.create!(first_name: "Player", last_name: "B1", email: "b1@example.com", password: "password123")
    @player_b2 = User.create!(first_name: "Player", last_name: "B2", email: "b2@example.com", password: "password123")

    @team_a.add_player(@player_a1)
    @team_a.add_player(@player_a2)
    @team_b.add_player(@player_b1)
    @team_b.add_player(@player_b2)

    # Assign teams to tournament
    @tournament.update!(team_a: @team_a, team_b: @team_b)

    @match = Match.create!(
      round: @round,
      match_type: "singles_match_play"
    )

    # Add players to match
    MatchPlayer.create!(match: @match, team: @team_a, user: @player_a1)
    MatchPlayer.create!(match: @match, team: @team_b, user: @player_b1)
  end

  test "should redirect non-admin users" do
    sign_in @non_admin_user
    get admin_tournament_round_matches_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id)
    assert_redirected_to root_path
  end

  test "should get index for admin" do
    sign_in @admin
    get admin_tournament_round_matches_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id)
    assert_response :success
    assert_includes response.body, @match.display_name
  end

  test "should show match for admin" do
    sign_in @admin
    get admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    assert_response :success
    assert_includes response.body, @match.display_name
    assert_includes response.body, @match.match_type_display
  end

  test "should get new match form for admin" do
    sign_in @admin
    get new_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id)
    assert_response :success
    assert_includes response.body, "Create New Match"
  end

  test "should create match for admin" do
    sign_in @admin

    assert_difference("Match.count") do
      post admin_tournament_round_matches_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id), params: {
        match: {
          match_type: "fourball_match_play",
          scheduled_time: 2.hours.from_now,
          golf_course_id: "1",
          golf_course_name: "Test Golf Course",
          golf_course_location: "Test Location"
        }
      }
    end

    assert_redirected_to admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: Match.last.id)
    assert_equal "Match was successfully created with course: Test Golf Course", flash[:notice]
  end

  test "should not create match without golf course" do
    sign_in @admin

    assert_no_difference("Match.count") do
      post admin_tournament_round_matches_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id), params: {
        match: {
          match_type: "singles_match_play"
          # Missing golf course data
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit match form for admin" do
    sign_in @admin
    get edit_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    assert_response :success
    assert_includes response.body, "Edit Match"
  end

  test "should update match for admin" do
    sign_in @admin

    patch admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id), params: {
      match: {
        match_type: "fourball_match_play",
        scheduled_time: 3.hours.from_now,
        golf_course_id: "1",
        golf_course_name: "Updated Golf Course",
        golf_course_location: "Updated Location"
      }
    }

    assert_redirected_to admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    assert_equal "Match was successfully updated.", flash[:notice]

    @match.reload
    assert_equal "fourball_match_play", @match.match_type
  end

  test "should not update match without golf course" do
    sign_in @admin

    patch admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id), params: {
      match: {
        match_type: "fourball_match_play"
        # Missing golf course data
      }
    }

    assert_response :unprocessable_entity
  end

  test "should delete match for admin" do
    sign_in @admin

    assert_difference("Match.count", -1) do
      delete admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    end

    assert_redirected_to admin_tournament_round_matches_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id)
    assert_equal "Match was successfully deleted.", flash[:notice]
  end

  test "should start match for admin" do
    sign_in @admin

    patch start_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)

    @match.reload
    assert @match.active?
    assert_redirected_to admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    assert_equal "Match has been started!", flash[:notice]
  end

  test "should complete match with winner for admin" do
    sign_in @admin

    patch complete_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id), params: {
      winner_team_id: @team_a.id
    }

    @match.reload
    assert @match.completed?
    assert_equal @team_a, @match.winner_team
    assert_not_nil @match.completed_at
    assert_redirected_to admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    assert_equal "Match has been completed!", flash[:notice]
  end

  test "should cancel match for admin" do
    sign_in @admin

    patch cancel_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)

    @match.reload
    assert @match.cancelled?
    assert_redirected_to admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    assert_equal "Match has been cancelled.", flash[:notice]
  end

  test "should add player to match" do
    sign_in @admin

    # Test adding a player to the match
    assert_difference("@match.match_players.count") do
      post add_player_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id), params: {
        team_id: @team_a.id,
        user_id: @player_a2.id
      }
    end

    assert_redirected_to players_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    assert_equal "Player was successfully added to the match.", flash[:notice]
  end

  test "should remove player from match" do
    sign_in @admin

    match_player = @match.match_players.first

    assert_difference("@match.match_players.count", -1) do
      delete remove_player_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id), params: {
        match_player_id: match_player.id
      }
    end

    assert_redirected_to players_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    assert_equal "Player was successfully removed from the match.", flash[:notice]
  end

  test "should not add invalid player to match" do
    sign_in @admin

    other_user = User.create!(first_name: "Other", last_name: "User", email: "other@example.com", password: "password123")

    assert_no_difference("@match.match_players.count") do
      post add_player_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id), params: {
        team_id: @team_a.id,
        user_id: other_user.id # Not a member of team_a
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "must be a member of the specified team"
  end

  test "should get players selection page" do
    sign_in @admin
    get players_admin_tournament_round_match_path(group_slug: @group.slug, tournament_id: @tournament.id, round_id: @round.id, id: @match.id)
    assert_response :success
    assert_includes response.body, "Manage Players"
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
