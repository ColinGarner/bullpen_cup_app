class Admin::DashboardController < Admin::BaseController
  def index
    # Dashboard is always scoped to the current group
    @group = current_group
    @upcoming_tournaments = @group.tournaments.upcoming.by_start_date.limit(5)
    @active_tournaments = @group.tournaments.active.by_start_date
    @recent_tournaments = @group.tournaments.completed.order(end_date: :desc).limit(3)
    @total_tournaments = @group.tournaments.count
    @total_teams = Team.joins(:tournament).where(tournaments: { group: @group }).count
    @total_users = @group.users.count
    @recent_activity = @group.tournaments.order(updated_at: :desc).limit(5)
  end

  def regenerate_invite_code
    current_group.regenerate_invite_code!
    redirect_to admin_group_admin_root_path(group_slug: current_group.slug),
                notice: "New invite code generated: #{current_group.invite_code}"
  end
end
