require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "status is upcoming when start date is in future" do
    tournament = Tournament.new(
      name: "Future Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user
    )

    assert_equal "upcoming", tournament.status
    assert tournament.upcoming?
    assert_not tournament.active?
    assert_not tournament.completed?
    assert_not tournament.cancelled?
  end

  test "status is active when current date is between start and end dates" do
    tournament = Tournament.new(
      name: "Active Tournament",
      start_date: 1.week.ago.to_date,
      end_date: 1.week.from_now.to_date,
      created_by: @user
    )

    assert_equal "active", tournament.status
    assert_not tournament.upcoming?
    assert tournament.active?
    assert_not tournament.completed?
    assert_not tournament.cancelled?
  end

  test "status is completed when end date is in past" do
    tournament = Tournament.new(
      name: "Past Tournament",
      start_date: 3.weeks.ago.to_date,
      end_date: 1.week.ago.to_date,
      created_by: @user
    )

    assert_equal "completed", tournament.status
    assert_not tournament.upcoming?
    assert_not tournament.active?
    assert tournament.completed?
    assert_not tournament.cancelled?
  end

  test "status is cancelled when cancelled flag is true regardless of dates" do
    # Upcoming tournament that's cancelled
    upcoming_cancelled = Tournament.new(
      name: "Cancelled Upcoming Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      cancelled: true,
      created_by: @user
    )

    assert_equal "cancelled", upcoming_cancelled.status
    assert_not upcoming_cancelled.upcoming?
    assert_not upcoming_cancelled.active?
    assert_not upcoming_cancelled.completed?
    assert upcoming_cancelled.cancelled?

    # Active tournament that's cancelled
    active_cancelled = Tournament.new(
      name: "Cancelled Active Tournament",
      start_date: 1.week.ago.to_date,
      end_date: 1.week.from_now.to_date,
      cancelled: true,
      created_by: @user
    )

    assert_equal "cancelled", active_cancelled.status
    assert active_cancelled.cancelled?

    # Completed tournament that's cancelled
    completed_cancelled = Tournament.new(
      name: "Cancelled Completed Tournament",
      start_date: 3.weeks.ago.to_date,
      end_date: 1.week.ago.to_date,
      cancelled: true,
      created_by: @user
    )

    assert_equal "cancelled", completed_cancelled.status
    assert completed_cancelled.cancelled?
  end

  test "status on exact start date is active" do
    tournament = Tournament.new(
      name: "Starting Today Tournament",
      start_date: Date.current,
      end_date: 1.week.from_now.to_date,
      created_by: @user
    )

    assert_equal "active", tournament.status
    assert tournament.active?
  end

  test "status on exact end date is active" do
    tournament = Tournament.new(
      name: "Ending Today Tournament",
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      created_by: @user
    )

    assert_equal "active", tournament.status
    assert tournament.active?
  end

  test "upcoming scope returns tournaments with future start dates" do
    upcoming_tournament = Tournament.create!(
      name: "Future Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user
    )

    active_tournament = Tournament.create!(
      name: "Active Tournament",
      start_date: 1.week.ago.to_date,
      end_date: 1.week.from_now.to_date,
      created_by: @user
    )

    completed_tournament = Tournament.create!(
      name: "Past Tournament",
      start_date: 3.weeks.ago.to_date,
      end_date: 1.week.ago.to_date,
      created_by: @user
    )

    upcoming_results = Tournament.upcoming
    assert_includes upcoming_results, upcoming_tournament
    assert_not_includes upcoming_results, active_tournament
    assert_not_includes upcoming_results, completed_tournament
  end

  test "active scope returns tournaments currently in progress" do
    upcoming_tournament = Tournament.create!(
      name: "Future Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user
    )

    active_tournament = Tournament.create!(
      name: "Active Tournament",
      start_date: 1.week.ago.to_date,
      end_date: 1.week.from_now.to_date,
      created_by: @user
    )

    completed_tournament = Tournament.create!(
      name: "Past Tournament",
      start_date: 3.weeks.ago.to_date,
      end_date: 1.week.ago.to_date,
      created_by: @user
    )

    active_results = Tournament.active
    assert_not_includes active_results, upcoming_tournament
    assert_includes active_results, active_tournament
    assert_not_includes active_results, completed_tournament
  end

  test "completed scope returns tournaments with past end dates" do
    upcoming_tournament = Tournament.create!(
      name: "Future Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user
    )

    active_tournament = Tournament.create!(
      name: "Active Tournament",
      start_date: 1.week.ago.to_date,
      end_date: 1.week.from_now.to_date,
      created_by: @user
    )

    completed_tournament = Tournament.create!(
      name: "Past Tournament",
      start_date: 3.weeks.ago.to_date,
      end_date: 1.week.ago.to_date,
      created_by: @user
    )

    completed_results = Tournament.completed
    assert_not_includes completed_results, upcoming_tournament
    assert_not_includes completed_results, active_tournament
    assert_includes completed_results, completed_tournament
  end

  test "cancelled scope returns tournaments with cancelled flag true" do
    regular_tournament = Tournament.create!(
      name: "Regular Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user
    )

    cancelled_tournament = Tournament.create!(
      name: "Cancelled Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      cancelled: true,
      created_by: @user
    )

    cancelled_results = Tournament.cancelled
    assert_not_includes cancelled_results, regular_tournament
    assert_includes cancelled_results, cancelled_tournament
  end

  test "cancel! method sets cancelled flag to true" do
    tournament = Tournament.create!(
      name: "Tournament to Cancel",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user
    )

    assert_not tournament.cancelled?
    assert_equal "upcoming", tournament.status

    tournament.cancel!
    tournament.reload

    assert tournament.cancelled?
    assert_equal "cancelled", tournament.status
  end

  test "status badge class returns correct CSS classes for each status" do
    upcoming_tournament = Tournament.new(
      name: "Future Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user
    )
    assert_equal "bg-blue-100 text-blue-800", upcoming_tournament.status_badge_class

    active_tournament = Tournament.new(
      name: "Active Tournament",
      start_date: 1.week.ago.to_date,
      end_date: 1.week.from_now.to_date,
      created_by: @user
    )
    assert_equal "bg-green-100 text-green-800", active_tournament.status_badge_class

    completed_tournament = Tournament.new(
      name: "Past Tournament",
      start_date: 3.weeks.ago.to_date,
      end_date: 1.week.ago.to_date,
      created_by: @user
    )
    assert_equal "bg-gray-100 text-gray-800", completed_tournament.status_badge_class

    cancelled_tournament = Tournament.new(
      name: "Cancelled Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      cancelled: true,
      created_by: @user
    )
    assert_equal "bg-red-100 text-red-800", cancelled_tournament.status_badge_class
  end

  test "scopes exclude cancelled tournaments" do
    upcoming_tournament = Tournament.create!(
      name: "Future Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      created_by: @user
    )

    cancelled_upcoming_tournament = Tournament.create!(
      name: "Cancelled Future Tournament",
      start_date: 1.week.from_now.to_date,
      end_date: 2.weeks.from_now.to_date,
      cancelled: true,
      created_by: @user
    )

    upcoming_results = Tournament.upcoming
    assert_includes upcoming_results, upcoming_tournament
    assert_not_includes upcoming_results, cancelled_upcoming_tournament
  end
end
