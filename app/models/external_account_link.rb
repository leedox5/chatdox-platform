class ExternalAccountLink < ApplicationRecord
  USERNAME_PATTERN = /\A[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}\z/

  belongs_to :user

  before_validation :assign_public_id, on: :create
  before_validation :normalize_github_username

  validates :public_id, presence: true, uniqueness: true
  validates :user_id, uniqueness: true
  validates :username, presence: true, format: { with: USERNAME_PATTERN }
  validates :normalized_username, presence: true

  def self.normalize_username(value)
    value.to_s.strip.sub(/\A@+/, "").downcase
  end

  def needs_invite?
    invited_at.blank?
  end

  def needs_revoke?
    invited_at.present? && revoked_at.blank?
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
end
