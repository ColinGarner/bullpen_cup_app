require "test_helper"

class ScoringHelperTest < ActionView::TestCase
  include ScoringHelper

  def setup
    # Mock available tees data for tee_options_grouped tests
    @available_tees = [
      {
        name: "Championship Tees",
        gender: "male",
        yardage: 7200,
        rating: 74.5,
        slope: 140,
        par: 72
      },
      {
        name: "Blue Tees",
        gender: "male",
        yardage: 6800,
        rating: 72.1,
        slope: 135,
        par: 72
      },
      {
        name: "White Tees",
        gender: "male",
        yardage: 6200,
        rating: 69.8,
        slope: 128,
        par: 72
      },
      {
        name: "Red Tees",
        gender: "female",
        yardage: 5400,
        rating: 71.2,
        slope: 125,
        par: 72
      },
      {
        name: "Gold Tees",
        gender: "female",
        yardage: 4900,
        rating: 68.5,
        slope: 118,
        par: 72
      }
    ]
  end

  # Difficulty Label Tests
  test "difficulty_label should return correct labels for different yardages" do
    # Beginner Friendly (0-5500)
    assert_equal "Beginner Friendly", difficulty_label(4800)
    assert_equal "Beginner Friendly", difficulty_label(5500)
    assert_equal "Beginner Friendly", difficulty_label(0)

    # Intermediate (5501-6200)
    assert_equal "Intermediate", difficulty_label(5501)
    assert_equal "Intermediate", difficulty_label(6000)
    assert_equal "Intermediate", difficulty_label(6200)

    # Challenging (6201-6800)
    assert_equal "Challenging", difficulty_label(6201)
    assert_equal "Challenging", difficulty_label(6500)
    assert_equal "Challenging", difficulty_label(6800)

    # Advanced (6801-7200)
    assert_equal "Advanced", difficulty_label(6801)
    assert_equal "Advanced", difficulty_label(7000)
    assert_equal "Advanced", difficulty_label(7200)

    # Championship (7201+)
    assert_equal "Championship", difficulty_label(7201)
    assert_equal "Championship", difficulty_label(7500)
    assert_equal "Championship", difficulty_label(8000)
  end

  test "difficulty_label should handle edge cases" do
    # Boundary conditions
    assert_equal "Beginner Friendly", difficulty_label(5500)
    assert_equal "Intermediate", difficulty_label(5501)
    assert_equal "Intermediate", difficulty_label(6200)
    assert_equal "Challenging", difficulty_label(6201)
    assert_equal "Challenging", difficulty_label(6800)
    assert_equal "Advanced", difficulty_label(6801)
    assert_equal "Advanced", difficulty_label(7200)
    assert_equal "Championship", difficulty_label(7201)
  end

  # Difficulty Percentage Tests
  test "difficulty_percentage should calculate correct percentages" do
    # Minimum value (5000 yards = 0%)
    assert_equal 0, difficulty_percentage(5000)
    assert_equal 0, difficulty_percentage(4000) # Below minimum gets clamped to 0

    # Maximum value (7500 yards = 100%)
    assert_equal 100, difficulty_percentage(7500)
    assert_equal 100, difficulty_percentage(8000) # Above maximum gets clamped to 100

    # Middle value (6250 yards = 50%)
    assert_equal 50, difficulty_percentage(6250)

    # Quarter value (5625 yards = 25%)
    assert_equal 25, difficulty_percentage(5625)

    # Three-quarter value (6875 yards = 75%)
    assert_equal 75, difficulty_percentage(6875)
  end

  test "difficulty_percentage should handle edge cases" do
    # Test clamping
    assert_equal 0, difficulty_percentage(-1000)
    assert_equal 100, difficulty_percentage(10000)

    # Test rounding
    assert_equal 33, difficulty_percentage(5833) # Should round 33.32 to 33
    assert_equal 47, difficulty_percentage(6167) # Should round 46.68 to 47
  end

  # Format Score Display Tests
  test "format_score_display should format scores correctly" do
    # Valid scores
    assert_equal "4", format_score_display(4)
    assert_equal "72", format_score_display(72)
    assert_equal "1", format_score_display(1)

    # Nil values
    assert_equal "—", format_score_display(nil)

    # Zero values
    assert_equal "—", format_score_display(0)
  end

  test "format_score_display should handle different data types" do
    # Integer numbers work
    assert_equal "5", format_score_display(5)

    # Float values
    assert_equal "4.0", format_score_display(4.0)

    # Large numbers
    assert_equal "150", format_score_display(150)

    # Note: String numbers would fail with zero? method, which is expected behavior
  end

  # Hole Difficulty Class Tests
  test "hole_difficulty_class should return correct CSS classes" do
    # Hardest holes (1-6)
    (1..6).each do |handicap|
      assert_equal "text-red-600 font-bold", hole_difficulty_class(handicap)
    end

    # Medium holes (7-12)
    (7..12).each do |handicap|
      assert_equal "text-yellow-600 font-semibold", hole_difficulty_class(handicap)
    end

    # Easier holes (13-18)
    (13..18).each do |handicap|
      assert_equal "text-green-600", hole_difficulty_class(handicap)
    end
  end

  test "hole_difficulty_class should handle edge cases" do
    # Boundary conditions
    assert_equal "text-red-600 font-bold", hole_difficulty_class(6)
    assert_equal "text-yellow-600 font-semibold", hole_difficulty_class(7)
    assert_equal "text-yellow-600 font-semibold", hole_difficulty_class(12)
    assert_equal "text-green-600", hole_difficulty_class(13)

    # Out of range values fall to the default (easiest) category
    assert_equal "text-green-600", hole_difficulty_class(0)
    assert_equal "text-green-600", hole_difficulty_class(19)
  end

  # Tee Options Grouped Tests
  test "tee_options_grouped should return empty array when no available tees" do
    @available_tees = nil
    assert_equal [], tee_options_grouped

    @available_tees = []
    assert_equal [], tee_options_grouped
  end

  test "tee_options_grouped should group tees by gender correctly" do
    options = tee_options_grouped

    # Should have two groups: Men's and Women's
    assert_equal 2, options.length

    # Check Men's group
    mens_group = options.find { |group| group[0] == "Men's" }
    assert_not_nil mens_group
    assert_equal "Men's", mens_group[0]
    assert_equal 3, mens_group[1].length # 3 male tees

    # Check Women's group
    womens_group = options.find { |group| group[0] == "Women's" }
    assert_not_nil womens_group
    assert_equal "Women's", womens_group[0]
    assert_equal 2, womens_group[1].length # 2 female tees
  end

  test "tee_options_grouped should format tee options correctly" do
    options = tee_options_grouped

    # Check a men's tee option format
    mens_options = options.find { |group| group[0] == "Men's" }[1]
    championship_option = mens_options.find { |opt| opt[1] == "Championship Tees" }

    assert_not_nil championship_option
    expected_label = "Championship Tees - 74.5/140 - 7,200 yards"
    assert_equal expected_label, championship_option[0]
    assert_equal "Championship Tees", championship_option[1]

    # Check a women's tee option format
    womens_options = options.find { |group| group[0] == "Women's" }[1]
    red_option = womens_options.find { |opt| opt[1] == "Red Tees" }

    assert_not_nil red_option
    expected_label = "Red Tees - 71.2/125 - 5,400 yards"
    assert_equal expected_label, red_option[0]
    assert_equal "Red Tees", red_option[1]
  end

  test "tee_options_grouped should handle only male tees" do
    @available_tees = @available_tees.select { |tee| tee[:gender] == "male" }

    options = tee_options_grouped

    assert_equal 1, options.length
    assert_equal "Men's", options[0][0]
    assert_equal 3, options[0][1].length
  end

  test "tee_options_grouped should handle only female tees" do
    @available_tees = @available_tees.select { |tee| tee[:gender] == "female" }

    options = tee_options_grouped

    assert_equal 1, options.length
    assert_equal "Women's", options[0][0]
    assert_equal 2, options[0][1].length
  end

  test "tee_options_grouped should order mens tees before womens tees" do
    options = tee_options_grouped

    assert_equal "Men's", options[0][0]
    assert_equal "Women's", options[1][0]
  end

  # Test number formatting in tee options
  test "tee_options_grouped should format large yardages with commas" do
    options = tee_options_grouped

    mens_options = options.find { |group| group[0] == "Men's" }[1]
    championship_option = mens_options.find { |opt| opt[1] == "Championship Tees" }

    # Should contain "7,200 yards" with comma
    assert_includes championship_option[0], "7,200 yards"
  end

  test "tee_options_grouped should format smaller yardages without unnecessary commas" do
    # Add a shorter course for testing
    @available_tees << {
      name: "Junior Tees",
      gender: "male",
      yardage: 800,
      rating: 60.0,
      slope: 110,
      par: 72
    }

    options = tee_options_grouped
    mens_options = options.find { |group| group[0] == "Men's" }[1]
    junior_option = mens_options.find { |opt| opt[1] == "Junior Tees" }

    # Should contain "800 yards" without comma
    assert_includes junior_option[0], "800 yards"
  end

  # Test missing data handling
  test "tee_options_grouped should handle missing tee data gracefully" do
    @available_tees = [
      {
        name: "Test Tees",
        gender: "male",
        yardage: nil,
        rating: 72.0,
        slope: 130,
        par: 72
      }
    ]

    # Should not raise an error
    assert_nothing_raised do
      options = tee_options_grouped
      assert_equal 1, options.length
    end
  end

  # Integration test with number_with_delimiter
  test "tee_options_grouped should use Rails number_with_delimiter helper" do
    # Mock the Rails helper method to ensure it's being called
    def number_with_delimiter(number)
      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end

    options = tee_options_grouped
    mens_options = options.find { |group| group[0] == "Men's" }[1]
    championship_option = mens_options.find { |opt| opt[1] == "Championship Tees" }

    # Should use the mocked delimiter method
    assert_includes championship_option[0], "7,200 yards"
  end

  private

  # Override the number_with_delimiter method for testing
  def number_with_delimiter(number)
    return "" if number.nil?
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
