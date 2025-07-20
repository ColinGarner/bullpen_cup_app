module TenantScoped
  extend ActiveSupport::Concern

  included do
    # Validate that the model has a group_id or belongs_to :group
    validates :group_id, presence: true

    # Default scope to current group if one is set
    scope :in_current_group, -> { where(group: Current.group) if Current.group&.persisted? }
    scope :in_group, ->(group) { where(group: group) if group&.persisted? }
  end

  class_methods do
    def tenant_scoped
      # Apply current group scope if group is set in Current context
      return all unless Current.group&.persisted?

      where(group: Current.group)
    end

    def with_group(group)
      return none unless group&.persisted?
      where(group: group)
    end

    def accessible_by_user(user)
      return none unless user&.persisted?
      # Return records from groups the user is a member of
      joins(:group).where(groups: { id: user.group_ids })
    end
  end

  # Instance methods
  def same_group?(other_record)
    return false unless other_record.respond_to?(:group_id)
    return false unless group_id.present? && other_record.group_id.present?
    group_id == other_record.group_id
  end

  def accessible_by_user?(user)
    return false unless user&.persisted? && group&.persisted?
    user.group_member?(group)
  end

  def in_current_group?
    return false unless Current.group&.persisted? && group&.persisted?
    group == Current.group
  end
end
