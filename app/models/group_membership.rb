class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  # Validations
  validates :role, presence: true, inclusion: { in: %w[admin member] }
  validates :user_id, uniqueness: { scope: :group_id, message: "is already a member of this group" }
  validates :joined_at, presence: true

  # Callbacks
  before_validation :set_joined_at, if: -> { joined_at.blank? }

  # Scopes
  scope :admins, -> { where(role: "admin") }
  scope :members, -> { where(role: "member") }
  scope :by_join_date, -> { order(:joined_at) }
  scope :recent, -> { order(joined_at: :desc) }

  # Constants
  ROLES = %w[admin member].freeze

  # Instance methods
  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end

  def promote_to_admin!
    update!(role: "admin")
  end

  def demote_to_member!
    update!(role: "member")
  end

  def role_display
    role.titleize
  end

  private

  def set_joined_at
    self.joined_at = Time.current
  end
end
