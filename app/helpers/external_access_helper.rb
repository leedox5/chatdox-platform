module ExternalAccessHelper
  LINK_STATUS_LABELS = {
    "pending_verification" => "계정 확인 대기",
    "verified" => "계정 확인 완료",
    "change_requested" => "기존 권한 회수 준비",
    "disabled" => "연결 해제"
  }.freeze
  GRANT_STATUS_LABELS = {
    "pending" => "라이선스 시작 대기",
    "grant_due" => "초대 준비",
    "invited" => "초대 발송·수락 대기",
    "active" => "Lab 접근 활성",
    "revoke_due" => "권한 회수 예정",
    "revoked" => "권한 회수 완료",
    "failed" => "운영 확인 필요"
  }.freeze

  def external_link_status_label(status)
    LINK_STATUS_LABELS.fetch(status, status)
  end

  def external_grant_status_label(status)
    GRANT_STATUS_LABELS.fetch(status, status)
  end
end
