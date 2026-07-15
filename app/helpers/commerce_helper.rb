module CommerceHelper
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
