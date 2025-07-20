class Current < ActiveSupport::CurrentAttributes
  attribute :user, :group

  def group=(group)
    super
    # Clear any cached associations when group changes
    clear_cached_associations
  end

  def group_tournaments
    @group_tournaments ||= group&.tournaments&.includes(:teams, :rounds) || Tournament.none
  end

  def group_teams
    @group_teams ||= group.present? ? Team.joins(:tournament).where(tournaments: { group: group }) : Team.none
  end

  def group_users
    @group_users ||= group&.users&.includes(:group_memberships) || User.none
  end

  def user_can_access_group?(check_group)
    return false unless user&.persisted? && check_group&.persisted?
    return true if user.admin? # Global admins can access any group

    user.group_member?(check_group)
  end

  def user_is_group_admin?
    return false unless user&.persisted? && group&.persisted?

    user.group_admin?(group)
  end

  def switch_group(new_group)
    return false unless new_group&.persisted?

    if user_can_access_group?(new_group)
      self.group = new_group
      true
    else
      false
    end
  end

  # Helper method to check if we have a valid group context
  def group_context?
    group&.persisted?
  end

  # Helper method to check if we have a valid user context
  def user_context?
    user&.persisted?
  end

  private

  def clear_cached_associations
    @group_tournaments = nil
    @group_teams = nil
    @group_users = nil
  end
end
