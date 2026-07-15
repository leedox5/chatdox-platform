module Admin::CommerceHelper
  def masked_email(user)
    local, domain = user.email.split("@", 2)
    return "user-#{user.id}" unless local && domain

    visible = local.first(2)
    "#{visible}***@#{domain}"
  end

  def order_status_label(status)
    {
      "pending" => "결제 대기",
      "paid" => "결제 완료",
      "failed" => "결제 실패",
      "canceled" => "취소",
      "abandoned" => "결제 이탈"
    }.fetch(status, status)
  end

  def refund_status_label(status)
    {
      "requested" => "접수",
      "reviewing" => "검토 중",
      "approved" => "승인",
      "rejected" => "거절",
      "processing" => "외부 처리 대기",
      "refunded" => "외부 처리 확인",
      "failed" => "처리 실패"
    }.fetch(status, status)
  end
end
