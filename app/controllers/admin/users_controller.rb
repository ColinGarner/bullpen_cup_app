class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :promote_to_group_admin, :demote_from_group_admin ]

  def index
    # Show only users who are members of the current group
    @users = current_group.users
                         .joins(:group_memberships)
                         .includes(:group_memberships)
                         .order("group_memberships.role DESC, users.last_name, users.first_name")

    # Simple search functionality
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @users = @users.where(
        "LOWER(users.first_name) LIKE ? OR LOWER(users.last_name) LIKE ? OR LOWER(users.email) LIKE ?",
        search_term, search_term, search_term
      )
    end

    @total_members = current_group.users.count
    @admin_members = current_group.group_memberships.where(role: "admin").count
  end

  def show
    @membership = @user.group_memberships.find_by(group: current_group)
    @user_tournaments = current_group.tournaments
                                    .joins(:teams)
                                    .joins("JOIN team_memberships ON teams.id = team_memberships.team_id")
                                    .where(team_memberships: { user_id: @user.id })
                                    .distinct
  end

  def promote_to_group_admin
    @membership = @user.group_memberships.find_by(group: current_group)

    if @membership.admin?
      redirect_to admin_users_path(group_slug: current_group.slug),
                  alert: "#{@user.display_name} is already a group admin."
      return
    end

    if @membership.update(role: "admin")
      redirect_to admin_users_path(group_slug: current_group.slug),
                  notice: "#{@user.display_name} has been promoted to group admin."
    else
      redirect_to admin_users_path(group_slug: current_group.slug),
                  alert: "Could not promote #{@user.display_name} to group admin."
    end
  end

  def demote_from_group_admin
    @membership = @user.group_memberships.find_by(group: current_group)

    # Prevent demoting the last group admin
    if current_group.admin_count <= 1
      redirect_to admin_users_path(group_slug: current_group.slug),
                  alert: "Cannot demote the last group admin. There must be at least one group admin."
      return
    end

    # Prevent self-demotion unless user is global admin
    if @user == current_user && !current_user.admin?
      redirect_to admin_users_path(group_slug: current_group.slug),
                  alert: "You cannot demote yourself. Ask another admin to do this."
      return
    end

    if @membership.update(role: "member")
      redirect_to admin_users_path(group_slug: current_group.slug),
                  notice: "#{@user.display_name} has been demoted to group member."
    else
      redirect_to admin_users_path(group_slug: current_group.slug),
                  alert: "Could not demote #{@user.display_name} from group admin."
    end
  end

  private

  def set_user
    @user = current_group.users.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_users_path(group_slug: current_group.slug),
                alert: "User not found in #{current_group.name}."
  end
end
