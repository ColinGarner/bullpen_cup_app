class Group < ApplicationRecord
  # Relationships
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :tournaments, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" },
            length: { minimum: 2, maximum: 50 }
  validates :description, length: { maximum: 1000 }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :active, inclusion: { in: [ true, false ] }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_validation :downcase_slug

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_name, -> { order(:name) }

  # Instance methods
  def active?
    active == true
  end

  def inactive?
    !active?
  end

  def member_count
    group_memberships.count
  end

  def admin_count
    group_memberships.where(role: "admin").count
  end

  def tournament_count
    tournaments.count
  end

  # Role-based membership methods
  def admins
    users.joins(:group_memberships).where(group_memberships: { role: "admin", group_id: id })
  end

  def members
    users.joins(:group_memberships).where(group_memberships: { role: "member", group_id: id })
  end

  def add_member(user, role: "member")
    group_memberships.find_or_create_by(user: user) do |membership|
      membership.role = role
      membership.joined_at = Time.current
    end
  end

  def remove_member(user)
    group_memberships.find_by(user: user)&.destroy
  end

  def member?(user)
    users.include?(user)
  end

  def admin?(user)
    group_memberships.find_by(user: user, role: "admin").present?
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9\s\-]/, "").gsub(/\s+/, "-")
  end

  def downcase_slug
    self.slug = slug&.downcase
  end
end
