require "test_helper"

class MatchPlayerTest < ActiveSupport::TestCase
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

    @player = User.create!(
      first_name: "Test",
      last_name: "Player",
      email: "test.player@example.com",
      password: "password123"
    )

    @team_a.add_player(@player)

    # Assign teams to tournament
    @tournament.update!(team_a: @team_a, team_b: @team_b)

    @match = Match.create!(
      round: @round,
      match_type: "singles_match_play"
    )
  end

  test "should create valid match player" do
    match_player = MatchPlayer.new(
      match: @match,
      team: @team_a,
      user: @player
    )

    assert match_player.valid?
    assert match_player.save
  end

  test "should require match" do
    match_player = MatchPlayer.new(
      team: @team_a,
      user: @player
    )

    assert_not match_player.valid?
    assert_includes match_player.errors[:match], "must exist"
  end

  test "should require team" do
    match_player = MatchPlayer.new(
      match: @match,
      user: @player
    )

    assert_not match_player.valid?
    assert_includes match_player.errors[:team], "must exist"
  end

  test "should require user" do
    match_player = MatchPlayer.new(
      match: @match,
      team: @team_a
    )

    assert_not match_player.valid?
    assert_includes match_player.errors[:user], "must exist"
  end

  test "should validate user is member of team" do
    other_player = User.create!(
      first_name: "Other",
      last_name: "Player",
      email: "other.player@example.com",
      password: "password123"
    )

    match_player = MatchPlayer.new(
      match: @match,
      team: @team_a,
      user: other_player
    )

    assert_not match_player.valid?
    assert_includes match_player.errors[:user], "must be a member of the specified team"
  end

  test "should validate team is part of the match" do
    other_team = Team.create!(
      name: "Other Team",
      tournament: @tournament,
      captain: @user
    )

    match_player = MatchPlayer.new(
      match: @match,
      team: other_team,
      user: @player
    )

    assert_not match_player.valid?
    assert_includes match_player.errors[:team], "must be one of the teams in this match"
  end

  test "should prevent duplicate player in same match" do
    MatchPlayer.create!(
      match: @match,
      team: @team_a,
      user: @player
    )

    duplicate_match_player = MatchPlayer.new(
      match: @match,
      team: @team_a,
      user: @player
    )

    assert_not duplicate_match_player.valid?
    assert_includes duplicate_match_player.errors[:user], "is already in this match"
  end

  test "should allow same player in different matches" do
    other_match = Match.create!(
      round: @round,
      match_type: "singles_match_play"
    )

    MatchPlayer.create!(
      match: @match,
      team: @team_a,
      user: @player
    )

    other_match_player = MatchPlayer.new(
      match: other_match,
      team: @team_a,
      user: @player
    )

    assert other_match_player.valid?
  end
end
