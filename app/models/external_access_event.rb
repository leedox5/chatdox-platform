class ExternalAccessEvent < ApplicationRecord
  ACTIONS = %w[
    link_requested link_verified link_renamed link_change_requested link_disabled
    grant_due grant_invited grant_activated grant_revoke_due grant_revoked grant_failed grant_retried
    task_created task_completed task_failed task_retried
  ].freeze

  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true
  belongs_to :external_account_link, optional: true
  belongs_to :external_access_grant, optional: true
  belongs_to :external_access_task, optional: true

  validates :action, inclusion: { in: ACTIONS }
  validates :occurred_at, presence: true
  validates :from_state, :to_state, :reason_code, length: { maximum: 100 }, allow_blank: true
  validates :evidence_note, length: { maximum: 1_000 }, allow_blank: true

  before_update { throw(:abort) }
  before_destroy { throw(:abort) }
end
