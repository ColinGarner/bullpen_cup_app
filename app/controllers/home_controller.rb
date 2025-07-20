class HomeController < ApplicationController
  skip_before_action :set_current_group, only: [ :index ]
  skip_before_action :ensure_group_access, only: [ :index ]

  def index
    if user_signed_in?
      handle_authenticated_user
    else
      handle_guest_user
    end
  end

  def select_group
    redirect_to root_path unless user_signed_in?
    @user_groups = current_user.groups.active.by_name.includes(:tournaments)
  end

  def switch_group
    redirect_to root_path unless user_signed_in?

    group = current_user.groups.find_by(slug: params[:group_slug])
    if group
      session[:current_group_id] = group.id
      redirect_to group_path(group.slug), notice: "Switched to #{group.name}"
    else
      redirect_to select_group_path, alert: "Group not found or you don't have access."
    end
  end

  private

  def handle_authenticated_user
    user_groups = current_user.groups.active

    case user_groups.count
    when 0
      # User has no groups - show onboarding
      @show_no_groups = true
      @available_groups = Group.active.by_name.limit(6)
      render :index
    else
      # Redirect to the actual select-group route
      redirect_to select_group_path
    end
  end

  def handle_guest_user
    # Show landing page with platform overview
    @featured_groups = Group.active.by_name.limit(3)
    @total_groups = Group.active.count
    @total_tournaments = Tournament.count
    @total_users = User.count
    render :index
  end
end
