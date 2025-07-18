class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:promote_to_admin, :demote_from_admin]

  def index
    @users = User.order(:admin, :last_name, :first_name)
    
    # Simple search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where(
        "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?", 
        search_term, search_term, search_term
      )
    end
  end

  def promote_to_admin
    if @user.admin?
      redirect_to admin_users_path, alert: "#{@user.display_name} is already an admin."
      return
    end
    
    if @user.update(admin: true)
      redirect_to admin_users_path, notice: "#{@user.display_name} has been promoted to admin."
    else
      redirect_to admin_users_path, alert: "Could not promote #{@user.display_name} to admin."
    end
  end

  def demote_from_admin
    # Prevent demoting the last admin
    if User.admins.count <= 1
      redirect_to admin_users_path, alert: "Cannot demote the last admin. There must be at least one admin."
      return
    end
    
    # Prevent self-demotion
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot demote yourself. Ask another admin to do this."
      return
    end
    
    if @user.update(admin: false)
      redirect_to admin_users_path, notice: "#{@user.display_name} has been demoted from admin."
    else
      redirect_to admin_users_path, alert: "Could not demote #{@user.display_name} from admin."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end 