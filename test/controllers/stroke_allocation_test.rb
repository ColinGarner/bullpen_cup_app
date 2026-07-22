require "test_helper"

# Tests for per-hole stroke allocation in ScoringController.
#
# These tests assert USGA-correct behavior: when the higher-handicap
# player's course-handicap difference from the low player exceeds 18,
# they receive a SECOND stroke on the hardest holes (2 strokes on
# stroke-index 1..N where N = diff - 18).
#
# The course is deliberately configured as slope 113, course rating 72.0,
# par 72 so Course Handicap == Handicap Index. That isolates the
# allocation logic from any rounding in the course-handicap formula.
class StrokeAllocationTest < ActionDispatch::IntegrationTest
  def setup
    @admin  = users(:two)
    @group  = groups(:one)

    @tournament = Tournament.create!(
      name: "Stroke Allocation Test",
      start_date: Date.today,
      end_date: 1.week.from_now.to_date,
      created_by: @admin,
      group: @group
    )

    @round = Round.create!(tournament: @tournament, round_number: 1, name: "R1")

    @team_a = Team.create!(name: "Team A", tournament: @tournament, captain: @admin)
    @team_b = Team.create!(name: "Team B", tournament: @tournament, captain: @admin)
    @tournament.update!(team_a: @team_a, team_b: @team_b)

    # Course tuned so course handicap == handicap index:
    #   slope 113 / 113 = 1.0, course_rating - par = 0.
    # Hole handicaps assigned 1..18 in hole order.
    @course_data = {
      "course" => {
        "tees" => {
          "male" => [ {
            "tee_name"      => "White",
            "total_yards"   => 6500,
            "course_rating" => 72.0,
            "slope_rating"  => 113,
            "par_total"     => 72,
            "holes" => Array.new(18) { |i| { "par" => 4, "handicap" => i + 1, "yardage" => 400 } }
          } ]
        }
      }
    }
  end

  # ---- helpers ----

  def build_match(match_type:)
    match = Match.create!(
      round: @round,
      match_type: match_type,
      scheduled_time: Time.current,
      golf_course_id: "test-course",
      status: "active",
      selected_tee_name: "White",
      holes_data: {
        "holes"       => @course_data["course"]["tees"]["male"][0]["holes"],
        "course_data" => @course_data
      }
    )
    match
  end

  def add_player(email:, handicap:, team:, match:)
    user = User.create!(
      first_name: "Player",
      last_name:  "Test#{handicap}",
      email:      email,
      password:   "password123",
      handicap:   handicap
    )
    team.add_player(user)
    MatchPlayer.create!(match: match, team: team, user: user)
    user
  end

  # Invoke the controller's private allocator against a prepared match.
  def strokes_for(player:, hole_handicap:, match:)
    controller = ScoringController.new
    controller.instance_variable_set(:@match, match)
    hole_data = { "handicap" => hole_handicap, "par" => 4 }
    method = case match.match_type
    when "singles_match_play"   then :calculate_singles_strokes_received
    when "fourball_match_play"  then :calculate_fourball_strokes_received
    when "scramble_match_play"  then :calculate_scramble_strokes_received
    else :calculate_singles_strokes_received
    end
    controller.send(method, player, hole_handicap, hole_data)
  end

  def total_strokes_over_round(player:, match:)
    (1..18).sum { |idx| strokes_for(player: player, hole_handicap: idx, match: match) }
  end

  # ---------------------------------------------------------------------------
  # Singles: mid-20s handicap vs single-digit opponent
  # Diff = 22 -> 1 stroke every hole PLUS a 2nd stroke on stroke-index 1..4
  # ---------------------------------------------------------------------------

  test "singles: 26 vs 4 gives two strokes on the hardest hole" do
    match  = build_match(match_type: "singles_match_play")
    high   = add_player(email: "hi26@t.co", handicap: 26, team: @team_a, match: match)
    _low   = add_player(email: "lo4@t.co",  handicap: 4,  team: @team_b, match: match)

    assert_equal 2, strokes_for(player: high, hole_handicap: 1, match: match),
      "Player with course-handicap diff of 22 should get 2 strokes on stroke-index 1"
  end

  test "singles: 26 vs 4 gives two strokes on holes with stroke index 1..4" do
    match = build_match(match_type: "singles_match_play")
    high  = add_player(email: "hi26b@t.co", handicap: 26, team: @team_a, match: match)
    _low  = add_player(email: "lo4b@t.co",  handicap: 4,  team: @team_b, match: match)

    (1..4).each do |idx|
      assert_equal 2, strokes_for(player: high, hole_handicap: idx, match: match),
        "Expected 2 strokes on stroke-index #{idx} (diff = 22)"
    end
    (5..18).each do |idx|
      assert_equal 1, strokes_for(player: high, hole_handicap: idx, match: match),
        "Expected 1 stroke on stroke-index #{idx} (diff = 22)"
    end
  end

  test "singles: total strokes over 18 holes equals course-handicap difference" do
    match = build_match(match_type: "singles_match_play")
    high  = add_player(email: "hi26c@t.co", handicap: 26, team: @team_a, match: match)
    _low  = add_player(email: "lo4c@t.co",  handicap: 4,  team: @team_b, match: match)

    # Course hcp diff = 22. Current buggy code caps at 18.
    assert_equal 22, total_strokes_over_round(player: high, match: match),
      "Sum of per-hole strokes across 18 holes must equal the course-handicap difference"
  end

  # ---------------------------------------------------------------------------
  # Boundary conditions
  # ---------------------------------------------------------------------------

  test "singles: diff of exactly 18 gives one stroke per hole and none doubled" do
    match = build_match(match_type: "singles_match_play")
    high  = add_player(email: "hi22@t.co", handicap: 22, team: @team_a, match: match)
    _low  = add_player(email: "lo4d@t.co", handicap: 4,  team: @team_b, match: match)

    (1..18).each do |idx|
      assert_equal 1, strokes_for(player: high, hole_handicap: idx, match: match),
        "Diff = 18: every hole gets exactly one stroke (index #{idx})"
    end
    assert_equal 18, total_strokes_over_round(player: high, match: match)
  end

  test "singles: diff of 19 gives second stroke on stroke-index 1 only" do
    match = build_match(match_type: "singles_match_play")
    high  = add_player(email: "hi23@t.co", handicap: 23, team: @team_a, match: match)
    _low  = add_player(email: "lo4e@t.co", handicap: 4,  team: @team_b, match: match)

    assert_equal 2, strokes_for(player: high, hole_handicap: 1, match: match),
      "Diff = 19: hole with stroke-index 1 should get 2 strokes"
    (2..18).each do |idx|
      assert_equal 1, strokes_for(player: high, hole_handicap: idx, match: match),
        "Diff = 19: hole with stroke-index #{idx} should get 1 stroke"
    end
    assert_equal 19, total_strokes_over_round(player: high, match: match)
  end

  # ---------------------------------------------------------------------------
  # Regression guard: normal small-difference cases stay correct
  # ---------------------------------------------------------------------------

  test "singles: diff of 8 gives strokes only on stroke-index 1..8" do
    match = build_match(match_type: "singles_match_play")
    high  = add_player(email: "hi12@t.co", handicap: 12, team: @team_a, match: match)
    _low  = add_player(email: "lo4f@t.co", handicap: 4,  team: @team_b, match: match)

    (1..8).each do |idx|
      assert_equal 1, strokes_for(player: high, hole_handicap: idx, match: match)
    end
    (9..18).each do |idx|
      assert_equal 0, strokes_for(player: high, hole_handicap: idx, match: match)
    end
    assert_equal 8, total_strokes_over_round(player: high, match: match)
  end

  test "singles: low player receives zero strokes" do
    match = build_match(match_type: "singles_match_play")
    _high = add_player(email: "hi26g@t.co", handicap: 26, team: @team_a, match: match)
    low   = add_player(email: "lo4g@t.co",  handicap: 4,  team: @team_b, match: match)

    (1..18).each do |idx|
      assert_equal 0, strokes_for(player: low, hole_handicap: idx, match: match),
        "Low player plays off scratch and should receive no strokes"
    end
  end

  # ---------------------------------------------------------------------------
  # Fourball: same allocator, verify the mid-20s player still gets doubled
  # strokes when they are the highest against a low-handicap opponent.
  # ---------------------------------------------------------------------------

  test "fourball: mid-20s player gets two strokes on stroke-index 1..4 vs a low of 4" do
    match = build_match(match_type: "fourball_match_play")
    high  = add_player(email: "fbhi26@t.co", handicap: 26, team: @team_a, match: match)
    _a2   = add_player(email: "fba12@t.co",  handicap: 12, team: @team_a, match: match)
    _b1   = add_player(email: "fbb4@t.co",   handicap: 4,  team: @team_b, match: match)
    _b2   = add_player(email: "fbb8@t.co",   handicap: 8,  team: @team_b, match: match)

    (1..4).each do |idx|
      assert_equal 2, strokes_for(player: high, hole_handicap: idx, match: match),
        "Fourball: player with hcp 26 vs low of 4 should get 2 strokes on stroke-index #{idx}"
    end
    assert_equal 22, total_strokes_over_round(player: high, match: match)
  end

  test "fourball: mid-tier player against a low of 4 gets one stroke each on stroke-index 1..8" do
    match = build_match(match_type: "fourball_match_play")
    _a1   = add_player(email: "fbhi26b@t.co", handicap: 26, team: @team_a, match: match)
    mid   = add_player(email: "fba12b@t.co",  handicap: 12, team: @team_a, match: match)
    _b1   = add_player(email: "fbb4b@t.co",   handicap: 4,  team: @team_b, match: match)
    _b2   = add_player(email: "fbb8b@t.co",   handicap: 8,  team: @team_b, match: match)

    # Diff for mid = 12 - 4 = 8. Should be one stroke on holes 1..8, zero elsewhere.
    (1..8).each do |idx|
      assert_equal 1, strokes_for(player: mid, hole_handicap: idx, match: match)
    end
    (9..18).each do |idx|
      assert_equal 0, strokes_for(player: mid, hole_handicap: idx, match: match)
    end
  end
end
