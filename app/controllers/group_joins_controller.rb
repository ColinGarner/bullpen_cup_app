class GroupJoinsController < ApplicationController
  before_action :authenticate_user!

  def new
    # Show form to enter group code
  end

  def create
    @invite_code = params[:invite_code]&.upcase&.strip
    @group = Group.find_by_invite_code(@invite_code)

    if @group.nil?
      flash.now[:alert] = "Invalid group code. Please check the code and try again."
      render :new, status: :unprocessable_entity
      return
    end

    if @group.member?(current_user)
      redirect_to group_dashboard_path(@group.slug),
                  notice: "You're already a member of #{@group.name}!"
      return
    end

    # Add user to the group as a member
    @group.add_member(current_user, role: "member")

    # Set the new group as current context
    Current.group = @group
    session[:current_group_id] = @group.id

    redirect_to group_dashboard_path(@group.slug),
                notice: "🎉 Welcome to #{@group.name}! You've successfully joined the group."
  end
end
