require "test_helper"

class MatchTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @group = groups(:one)
    @tournament = Tournament.create!(
      name: "Test Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user,
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
      captain: @user
    )

    @team_b = Team.create!(
      name: "Team Beta",
      tournament: @tournament,
      captain: users(:two)
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
  end

  test "should create valid match" do
    match = Match.new(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    assert match.valid?
    assert match.save
  end

  test "should require round" do
    match = Match.new(
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    assert_not match.valid?
    assert_includes match.errors[:round], "must exist"
  end

  test "should require team_a" do
    match = Match.new(
      round: @round,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    assert_not match.valid?
    assert_includes match.errors[:team_a], "must exist"
  end

  test "should require team_b" do
    match = Match.new(
      round: @round,
      team_a: @team_a,
      match_type: "singles_match_play"
    )

    assert_not match.valid?
    assert_includes match.errors[:team_b], "must exist"
  end

  test "should require match_type" do
    match = Match.new(
      round: @round,
      team_a: @team_a,
      team_b: @team_b
    )

    assert_not match.valid?
    assert_includes match.errors[:match_type], "can't be blank"
  end

  test "should not allow same team for team_a and team_b" do
    match = Match.new(
      round: @round,
      team_a: @team_a,
      team_b: @team_a,
      match_type: "singles_match_play"
    )

    assert_not match.valid?
    assert_includes match.errors[:team_b], "cannot be the same as Team A"
  end

  test "should validate teams belong to same tournament as round" do
    other_tournament = Tournament.create!(
      name: "Other Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user,
      group: @group
    )

    other_team = Team.create!(
      name: "Other Team",
      tournament: other_tournament,
      captain: @user
    )

    match = Match.new(
      round: @round,
      team_a: @team_a,
      team_b: other_team,
      match_type: "singles_match_play"
    )

    assert_not match.valid?
    assert_includes match.errors[:team_b], "must belong to the same tournament as the round"
  end

  test "should have valid match_type enum values" do
    valid_types = %w[fourball_match_play alt_shot_match_play singles_match_play stableford]

    valid_types.each do |match_type|
      match = Match.new(
        round: @round,
        team_a: @team_a,
        team_b: @team_b,
        match_type: match_type
      )
      assert match.valid?, "#{match_type} should be valid"
    end
  end

  test "should not accept invalid match_type" do
    match = Match.new(
      round: @round,
      team_a: @team_a,
      team_b: @team_b
    )

    # Rails enums throw ArgumentError when setting invalid values
    assert_raises(ArgumentError) do
      match.match_type = "invalid_type"
    end
  end

  test "should have valid status enum values" do
    valid_statuses = %w[upcoming active completed cancelled]

    valid_statuses.each do |status|
      match = Match.create!(
        round: @round,
        team_a: @team_a,
        team_b: @team_b,
        match_type: "singles_match_play",
        status: status
      )
      assert_equal status, match.status
    end
  end

  test "should default status to upcoming" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    assert_equal "upcoming", match.status
    assert match.upcoming?
  end

  test "should validate correct number of players for singles_match_play" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    # Add correct number of players (1 per team)
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a1)
    MatchPlayer.create!(match: match, team: @team_b, user: @player_b1)

    assert match.valid_player_count?
    assert_equal 2, match.match_players.count
  end

  test "should validate correct number of players for fourball_match_play" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "fourball_match_play"
    )

    # Add correct number of players (2 per team)
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a1)
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a2)
    MatchPlayer.create!(match: match, team: @team_b, user: @player_b1)
    MatchPlayer.create!(match: match, team: @team_b, user: @player_b2)

    assert match.valid_player_count?
    assert_equal 4, match.match_players.count
  end

  test "should validate correct number of players for alt_shot_match_play" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "alt_shot_match_play"
    )

    # Add correct number of players (2 per team)
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a1)
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a2)
    MatchPlayer.create!(match: match, team: @team_b, user: @player_b1)
    MatchPlayer.create!(match: match, team: @team_b, user: @player_b2)

    assert match.valid_player_count?
    assert_equal 4, match.match_players.count
  end

  test "should invalidate incorrect player count for singles_match_play" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    # Add too many players
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a1)
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a2)
    MatchPlayer.create!(match: match, team: @team_b, user: @player_b1)

    assert_not match.valid_player_count?
  end

  test "should invalidate uneven teams" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "fourball_match_play"
    )

    # Add uneven number of players per team
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a1)
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a2)
    MatchPlayer.create!(match: match, team: @team_b, user: @player_b1)
    # Missing second player for team_b

    assert_not match.valid_player_count?
  end

  test "should validate players belong to correct teams" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    # Try to add player from team_a to team_b in match
    match_player = MatchPlayer.new(match: match, team: @team_b, user: @player_a1)

    assert_not match_player.valid?
    assert_includes match_player.errors[:user], "must be a member of the specified team"
  end

  test "should allow setting winner_team" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play",
      winner_team: @team_a
    )

    assert_equal @team_a, match.winner_team
  end

  test "winner_team must be one of the competing teams" do
    other_team = Team.create!(
      name: "Other Team",
      tournament: @tournament,
      captain: @user
    )

    match = Match.new(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play",
      winner_team: other_team
    )

    assert_not match.valid?
    assert_includes match.errors[:winner_team], "must be one of the competing teams"
  end

  test "should complete match with winner" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    assert match.upcoming?

    match.complete_with_winner!(@team_a)

    assert match.completed?
    assert_equal @team_a, match.winner_team
    assert_not_nil match.completed_at
  end

  test "should get opposing team" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    assert_equal @team_b, match.opposing_team(@team_a)
    assert_equal @team_a, match.opposing_team(@team_b)
  end

  test "should return nil for opposing team if team not in match" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play"
    )

    other_team = Team.create!(
      name: "Other Team",
      tournament: @tournament,
      captain: @user
    )

    assert_nil match.opposing_team(other_team)
  end

  test "should get players for team" do
    match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "fourball_match_play"
    )

    MatchPlayer.create!(match: match, team: @team_a, user: @player_a1)
    MatchPlayer.create!(match: match, team: @team_a, user: @player_a2)
    MatchPlayer.create!(match: match, team: @team_b, user: @player_b1)
    MatchPlayer.create!(match: match, team: @team_b, user: @player_b2)

    team_a_players = match.players_for_team(@team_a)
    team_b_players = match.players_for_team(@team_b)

    assert_equal 2, team_a_players.count
    assert_includes team_a_players, @player_a1
    assert_includes team_a_players, @player_a2

    assert_equal 2, team_b_players.count
    assert_includes team_b_players, @player_b1
    assert_includes team_b_players, @player_b2
  end
end
