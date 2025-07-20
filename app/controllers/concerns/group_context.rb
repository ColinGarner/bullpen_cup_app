module GroupContext
  extend ActiveSupport::Concern

  included do
    before_action :set_current_group
    before_action :ensure_group_access

    # Define helper methods when the module is included in the controller
    helper_method :current_group, :current_group_id, :current_group_name, :current_group_slug,
                  :user_groups, :user_can_switch_groups?, :user_is_group_admin?, :user_is_group_member?
  end

  private

  def set_current_group
    Current.user = current_user

    # Try to find group from params, subdomain, or session
    group = find_group_from_request

    if group && current_user&.group_member?(group)
      Current.group = group
      session[:current_group_id] = group.id
    elsif session[:current_group_id] && current_user
      # Try to restore from session
      session_group = current_user.groups.find_by(id: session[:current_group_id])
      Current.group = session_group if session_group
    elsif current_user&.groups&.any?
      # Default to first group if user has groups
      Current.group = current_user.groups.first
      session[:current_group_id] = Current.group.id
    end
  end

  def find_group_from_request
    # Priority order: params[:group_slug], subdomain, params[:group_id]

    if params[:group_slug].present?
      Group.find_by(slug: params[:group_slug])
    elsif request.subdomain.present? && request.subdomain != "www"
      Group.find_by(slug: request.subdomain)
    elsif params[:group_id].present?
      Group.find_by(id: params[:group_id])
    end
  end

  def ensure_group_access
    return if Current.group.blank?
    return if current_user&.admin? # Global admins bypass group restrictions

    unless current_user&.group_member?(Current.group)
      redirect_to root_path, alert: "You don't have access to this group."
    end
  end

  def require_group_admin
    unless Current.user_is_group_admin?
      redirect_to root_path, alert: "You must be a group administrator to perform this action."
    end
  end

  def require_group_context
    unless current_group
      redirect_to select_group_path, alert: "Please select a group to continue."
    end
  end

  def switch_group(group_slug)
    new_group = Group.find_by(slug: group_slug)

    if new_group && Current.switch_group(new_group)
      session[:current_group_id] = new_group.id
      redirect_to request.referer || root_path, notice: "Switched to #{new_group.name}"
    else
      redirect_to request.referer || root_path, alert: "Unable to switch to that group."
    end
  end

  # Public helper methods for views and controllers
  def current_group
    Current.group
  end

  def current_group_id
    Current.group&.id
  end

  def current_group_name
    Current.group&.name
  end

  def current_group_slug
    Current.group&.slug
  end

  def user_groups
    @user_groups ||= current_user&.groups&.active&.by_name || Group.none
  end

  def user_can_switch_groups?
    user_groups.count > 1
  end

  def user_is_group_admin?
    Current.user_is_group_admin?
  end

  def user_is_group_member?
    current_user&.group_member?(current_group)
  end
end
