module Admin::ExternalAccessHelper
  def external_task_label(task_type)
    {
      "verify_account" => "계정 확인",
      "send_invite" => "초대 발송 기록",
      "confirm_acceptance" => "수락 확인",
      "revoke_access" => "권한 회수 기록",
      "confirm_revocation" => "회수 완료 확인",
      "process_account_change" => "계정 변경 판정"
    }.fetch(task_type, task_type)
  end

  def masked_external_access_user(user)
    local, domain = user.email.split("@", 2)
    "#{local.first(2)}***@#{domain}"
  end
end
