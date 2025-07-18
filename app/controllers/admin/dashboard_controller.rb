class Admin::DashboardController < Admin::BaseController
  def index
    @upcoming_tournaments = Tournament.upcoming.by_start_date.limit(5)
    @active_tournaments = Tournament.active.by_start_date
    @recent_tournaments = Tournament.completed.order(end_date: :desc).limit(3)
    @total_tournaments = Tournament.count
  end
end
