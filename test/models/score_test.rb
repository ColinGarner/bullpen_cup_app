require "test_helper"

class ScoreTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @group = groups(:one)

    # Create tournament, round, teams, and match
    @tournament = Tournament.create!(
      name: "Test Tournament",
      start_date: Date.today,
      end_date: 1.week.from_now.to_date,
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
      password: "password123",
      handicap: 10
    )

    @match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "singles_match_play",
      holes_data: {
        "holes" => Array.new(18) { |i| { "par" => 4, "handicap" => i + 1 } }
      }
    )
  end

  # Association Tests
  test "should belong to match" do
    score = Score.new(
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:match], "must exist"
  end

  test "should belong to user" do
    score = Score.new(
      match: @match,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:user], "must exist"
  end

  # Validation Tests
  test "should create valid score" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert score.valid?
    assert score.save
  end

  test "should require hole_number" do
    score = Score.new(
      match: @match,
      user: @player,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:hole_number], "can't be blank"
  end

  test "should validate hole_number is positive" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 0,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:hole_number], "must be greater than 0"
  end

  test "should validate hole_number is not greater than 18" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 19,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:hole_number], "must be less than or equal to 18"
  end

  test "should require strokes" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:strokes], "can't be blank"
  end

  test "should validate strokes is positive" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 0,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:strokes], "must be greater than 0"
  end

  test "should validate strokes is not greater than 15" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 16,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:strokes], "must be less than or equal to 15"
  end

  test "should require net_strokes" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:net_strokes], "can't be blank"
  end

  test "should validate net_strokes is positive" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 0,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:net_strokes], "must be greater than 0"
  end

  test "should validate net_strokes is not greater than 15" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 16,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:net_strokes], "must be less than or equal to 15"
  end

  test "should require handicap_used" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:handicap_used], "can't be blank"
  end

  test "should validate handicap_used is not negative" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: -1,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:handicap_used], "must be greater than or equal to 0"
  end

  test "should validate handicap_used is not greater than 54" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 55,
      strokes_received_on_hole: 0
    )

    assert_not score.valid?
    assert_includes score.errors[:handicap_used], "must be less than or equal to 54"
  end

  test "should require strokes_received_on_hole" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: nil
    )

    assert_not score.valid?
    assert_includes score.errors[:strokes_received_on_hole], "can't be blank"
  end

  test "should validate strokes_received_on_hole is not negative" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: -1
    )

    assert_not score.valid?
    assert_includes score.errors[:strokes_received_on_hole], "must be greater than or equal to 0"
  end

  test "should validate strokes_received_on_hole is not greater than 3" do
    score = Score.new(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 4
    )

    assert_not score.valid?
    assert_includes score.errors[:strokes_received_on_hole], "must be less than or equal to 3"
  end

  test "should validate hole_result inclusion" do
    # Valid values should work
    %w[won lost halved pending].each_with_index do |result, index|
      score = Score.create!(
        match: @match,
        user: @player,
        hole_number: index + 1, # Use different hole numbers to avoid uniqueness constraint
        strokes: 4,
        net_strokes: 4,
        handicap_used: 10,
        strokes_received_on_hole: 0,
        hole_result: result
      )
      assert_equal result, score.hole_result
    end
  end

  test "should allow nil hole_result" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0,
      hole_result: nil
    )
    assert_nil score.hole_result
  end

  # Scope Tests
  test "for_match scope should return scores for specific match" do
    other_match = Match.create!(
      round: @round,
      team_a: @team_a,
      team_b: @team_b,
      match_type: "fourball_match_play"
    )

    score1 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    score2 = Score.create!(
      match: other_match,
      user: @player,
      hole_number: 1,
      strokes: 5,
      net_strokes: 5,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    scores = Score.for_match(@match)
    assert_includes scores, score1
    assert_not_includes scores, score2
  end

  test "for_user scope should return scores for specific user" do
    other_player = User.create!(
      first_name: "Other",
      last_name: "Player",
      email: "other@example.com",
      password: "password123"
    )

    score1 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    score2 = Score.create!(
      match: @match,
      user: other_player,
      hole_number: 1,
      strokes: 5,
      net_strokes: 5,
      handicap_used: 15,
      strokes_received_on_hole: 0
    )

    scores = Score.for_user(@player)
    assert_includes scores, score1
    assert_not_includes scores, score2
  end

  test "for_hole scope should return scores for specific hole" do
    score1 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    score2 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 2,
      strokes: 5,
      net_strokes: 5,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    scores = Score.for_hole(1)
    assert_includes scores, score1
    assert_not_includes scores, score2
  end

  test "completed_holes scope should return scores with strokes" do
    score1 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    # This shouldn't happen in real usage due to validations, but test the scope
    score2 = Score.new(
      match: @match,
      user: @player,
      hole_number: 2,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )
    score2.save(validate: false) # Skip validations for this test

    scores = Score.completed_holes
    assert_includes scores, score1
    assert_not_includes scores, score2
  end

  test "match_play_results scope should return scores with hole_result" do
    score1 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0,
      hole_result: "won"
    )

    score2 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 2,
      strokes: 5,
      net_strokes: 5,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    scores = Score.match_play_results
    assert_includes scores, score1
    assert_not_includes scores, score2
  end

  # Class Method Tests
  test "for_match_and_hole should return scores for specific match and hole" do
    score1 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    score2 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 2,
      strokes: 5,
      net_strokes: 5,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    scores = Score.for_match_and_hole(@match, 1)
    assert_includes scores, score1
    assert_not_includes scores, score2
  end

  test "total_strokes_for_user should calculate total strokes" do
    Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    Score.create!(
      match: @match,
      user: @player,
      hole_number: 2,
      strokes: 5,
      net_strokes: 5,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    total = Score.total_strokes_for_user(@player, @match)
    assert_equal 9, total
  end

  test "total_net_strokes_for_user should calculate total net strokes" do
    Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 5,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 1
    )

    Score.create!(
      match: @match,
      user: @player,
      hole_number: 2,
      strokes: 6,
      net_strokes: 5,
      handicap_used: 10,
      strokes_received_on_hole: 1
    )

    total = Score.total_net_strokes_for_user(@player, @match)
    assert_equal 9, total
  end

  # Instance Method Tests
  test "gross_score should return strokes" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 3,
      handicap_used: 10,
      strokes_received_on_hole: 1
    )

    assert_equal 4, score.gross_score
  end

  test "net_score should return net_strokes" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 3,
      handicap_used: 10,
      strokes_received_on_hole: 1
    )

    assert_equal 3, score.net_score
  end

  test "received_strokes? should return true when strokes received" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 3,
      handicap_used: 10,
      strokes_received_on_hole: 1
    )

    assert score.received_strokes?
  end

  test "received_strokes? should return false when no strokes received" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_not score.received_strokes?
  end

  test "calculate_net_score should return correct net score" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 5,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 1
    )

    assert_equal 4, score.calculate_net_score
  end

  test "match_play_won? should return true when won" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0,
      hole_result: "won"
    )

    assert score.match_play_won?
  end

  test "match_play_lost? should return true when lost" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0,
      hole_result: "lost"
    )

    assert score.match_play_lost?
  end

  test "match_play_halved? should return true when halved" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0,
      hole_result: "halved"
    )

    assert score.match_play_halved?
  end

  test "match_play_pending? should return true when pending or nil" do
    score1 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0,
      hole_result: "pending"
    )

    score2 = Score.create!(
      match: @match,
      user: @player,
      hole_number: 2,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0,
      hole_result: nil
    )

    assert score1.match_play_pending?
    assert score2.match_play_pending?
  end

  test "calculate_and_set_net_score! should update net_strokes" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 5,
      net_strokes: 4, # Wrong initial value
      handicap_used: 10,
      strokes_received_on_hole: 1
    )

    score.calculate_and_set_net_score!
    assert_equal 4, score.net_strokes # 5 - 1 = 4
  end

  test "score_display should show strokes only when no strokes received" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_equal "4", score.score_display
  end

  test "score_display should show detailed info when strokes received" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 5,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 1
    )

    assert_equal "5 (4 net, 1 stroke)", score.score_display
  end

  test "score_display should pluralize strokes correctly" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 6,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 2
    )

    assert_equal "6 (4 net, 2 strokes)", score.score_display
  end

  test "hole_result_display should return correct symbols" do
    results = {
      "won" => "✓",
      "lost" => "✗",
      "halved" => "½",
      nil => "-",
      "pending" => "-"
    }

    results.each_with_index do |(result, symbol), index|
      score = Score.create!(
        match: @match,
        user: @player,
        hole_number: index + 10, # Use different hole numbers to avoid uniqueness constraint
        strokes: 4,
        net_strokes: 4,
        handicap_used: 10,
        strokes_received_on_hole: 0,
        hole_result: result
      )

      assert_equal symbol, score.hole_result_display
    end
  end

  test "handicap_at_time_of_scoring should return handicap_used" do
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 12,
      strokes_received_on_hole: 0
    )

    assert_equal 12, score.handicap_at_time_of_scoring
  end

  test "par_for_hole should return default when no hole data" do
    @match.update!(holes_data: nil)
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_equal 4, score.par_for_hole
  end

  test "handicap_index_for_hole should return default when no hole data" do
    @match.update!(holes_data: nil)
    score = Score.create!(
      match: @match,
      user: @player,
      hole_number: 1,
      strokes: 4,
      net_strokes: 4,
      handicap_used: 10,
      strokes_received_on_hole: 0
    )

    assert_equal 10, score.handicap_index_for_hole
  end
end
