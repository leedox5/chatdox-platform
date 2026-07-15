class ExternalAccessGrant < ApplicationRecord
  STATUSES = %w[pending grant_due invited active revoke_due revoked failed].freeze
  LIVE_STATUSES = %w[grant_due invited active revoke_due].freeze
  TRANSITIONS = {
    "pending" => %w[grant_due failed],
    "grant_due" => %w[invited revoke_due failed],
    "invited" => %w[active revoke_due failed],
    "active" => %w[revoke_due failed],
    "revoke_due" => %w[revoked failed],
    "revoked" => [],
    "failed" => %w[pending grant_due invited active revoke_due]
  }.freeze

  belongs_to :user
  belongs_to :product
  belongs_to :license
  belongs_to :external_account_link
  has_many :external_access_tasks, dependent: :restrict_with_error
  has_many :external_access_events, dependent: :restrict_with_error

  before_validation :assign_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true
  validates :repository_key, inclusion: { in: %w[chatdox_lab] }
  validates :status, inclusion: { in: STATUSES }
  validates :resume_state, inclusion: { in: STATUSES - %w[failed] }, allow_nil: true
  validates :failure_reason_code, length: { maximum: 100 }, allow_nil: true
  validates :public_message, :internal_note, length: { maximum: 1_000 }, allow_blank: true
  validates :license_id, uniqueness: { scope: %i[external_account_link_id repository_key] }
  validate :relationships_match
  validate :one_live_grant_per_product
  validate :active_state_has_current_entitlement

  scope :live, -> { where(status: LIVE_STATUSES) }

  def transition_to!(target, attributes = {}, at: Time.current)
    target = target.to_s
    raise ArgumentError, "invalid grant transition: #{status} -> #{target}" unless TRANSITIONS.fetch(status).include?(target)

    assign_attributes(attributes.merge(status: target))
    save!(context: validation_context_for(target, at))
  end

  private

  def assign_public_id
    self.public_id ||= SecureRandom.hex(12)
  end

  def relationships_match
    errors.add(:license, "must belong to the grant user") if license && license.user_id != user_id
    errors.add(:license, "must match the grant product") if license && license.product_id != product_id
    if external_account_link && external_account_link.user_id != user_id
      errors.add(:external_account_link, "must belong to the grant user")
    end
  end

  def one_live_grant_per_product
    return unless LIVE_STATUSES.include?(status) && user_id && product_id

    conflict = self.class.live.where(user_id: user_id, product_id: product_id).where.not(id: id).exists?
    errors.add(:base, "only one live grant is allowed per user and product") if conflict
  end

  def active_state_has_current_entitlement
    return unless %w[invited active].include?(status)
    return unless validation_context.to_s.start_with?("at:")

    at = Time.iso8601(validation_context.to_s.delete_prefix("at:"))
    errors.add(:license, "must be active") unless license&.active_at?(at)
    errors.add(:external_account_link, "must be verified") unless external_account_link&.verified?
  end

  def validation_context_for(target, at)
    %w[invited active].include?(target) ? "at:#{at.utc.iso8601}" : nil
  end
end
