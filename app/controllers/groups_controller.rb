class GroupsController < ApplicationController
  skip_before_action :set_current_group
  skip_before_action :ensure_group_access

  before_action :authenticate_user!
  before_action :find_group_by_slug, only: [ :show, :dashboard ]
  before_action :ensure_group_member, only: [ :show, :dashboard ]

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      # Add the creator as an admin of the group
      @group.add_member(current_user, role: "admin")

      # Set the new group as current
      Current.group = @group
      session[:current_group_id] = @group.id

      redirect_to group_dashboard_path(@group.slug),
                  notice: "#{@group.name} has been created successfully! You are now an administrator."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Set the current group context
    Current.group = @group
    session[:current_group_id] = @group.id

    # Always redirect to the group home page - users can choose admin portal from there
    redirect_to group_dashboard_path(@group.slug)
  end

  def dashboard
    # Set the current group context
    Current.group = @group
    session[:current_group_id] = @group.id

    # Load dashboard data
    @upcoming_tournaments = @group.tournaments.upcoming.limit(3)
    @active_tournaments = @group.tournaments.active.limit(3)
    @recent_tournaments = @group.tournaments.completed.order(end_date: :desc).limit(3)

    # User's participation
    @user_teams = current_user.teams.joins(:tournament).where(tournaments: { group: @group })
    @user_upcoming_matches = current_user.matches.joins(round: :tournament)
                                        .where(tournaments: { group: @group })
                                        .where(status: [ "upcoming", "active" ])
                                        .includes(:round, :team_a, :team_b)
                                        .order("rounds.round_number ASC, scheduled_time ASC")
                                        .limit(5)
  end

  private

  def find_group_by_slug
    @group = Group.find_by(slug: params[:group_slug])

    unless @group
      redirect_to root_path, alert: "Group not found."
    end
  end

  def ensure_group_member
    unless current_user.admin? || current_user.group_member?(@group)
      redirect_to root_path, alert: "You don't have access to this group."
    end
  end

  def group_params
    params.require(:group).permit(:name, :description, :contact_email, :contact_phone, :address)
  end
end
