class ExternalAccountLink < ApplicationRecord
  PROVIDERS = %w[github].freeze
  STATUSES = %w[pending_verification verified change_requested disabled].freeze
  USERNAME_PATTERN = /\A[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}\z/

  belongs_to :user
  belongs_to :replaces_link, class_name: "ExternalAccountLink", optional: true
  has_one :replacement_link, class_name: "ExternalAccountLink", foreign_key: :replaces_link_id,
    dependent: :restrict_with_error, inverse_of: :replaces_link
  has_many :external_access_grants, dependent: :restrict_with_error
  has_many :external_access_tasks, dependent: :restrict_with_error
  has_many :external_access_events, dependent: :restrict_with_error

  before_validation :assign_public_id, on: :create
  before_validation :normalize_github_username

  validates :public_id, presence: true, uniqueness: true
  validates :provider, inclusion: { in: PROVIDERS }
  validates :status, inclusion: { in: STATUSES }
  validates :username, presence: true, format: { with: USERNAME_PATTERN }
  validates :normalized_username, presence: true
  validates :external_uid, format: { with: /\A\d+\z/ }, allow_nil: true
  validate :unique_active_identity
  validate :replacement_belongs_to_same_user

  scope :available, -> { where.not(status: "disabled") }
  scope :verified, -> { where(status: "verified") }

  def self.normalize_username(value)
    value.to_s.strip.sub(/\A@+/, "").downcase
  end

  def verified?
    status == "verified"
  end

  private

  def assign_public_id
    self.public_id ||= SecureRandom.hex(12)
  end

  def normalize_github_username
    self.username = username.to_s.strip.sub(/\A@+/, "")
    self.normalized_username = self.class.normalize_username(username)
    self.provider = "github"
  end

  def unique_active_identity
    return if status == "disabled"

    username_conflict = self.class.available.where(provider: provider, normalized_username: normalized_username)
      .where.not(id: id).exists?
    errors.add(:username, "is already connected") if username_conflict

    return if external_uid.blank?

    uid_conflict = self.class.available.where(provider: provider, external_uid: external_uid)
      .where.not(id: id).exists?
    errors.add(:external_uid, "is already connected") if uid_conflict
  end

  def replacement_belongs_to_same_user
    return unless replaces_link && replaces_link.user_id != user_id

    errors.add(:replaces_link, "must belong to the same user")
  end
end
