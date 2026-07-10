module DashboardHelper
  SUBSCRIPTION_BADGES = {
    "active" => [ "구독 중", "bg-emerald-100 text-emerald-700" ],
    "past_due" => [ "결제 확인 필요", "bg-amber-100 text-amber-700" ],
    "canceled" => [ "해지됨", "bg-slate-100 text-slate-700" ],
    "expired" => [ "만료됨", "bg-rose-100 text-rose-700" ],
    "pending" => [ "결제 대기", "bg-blue-100 text-blue-700" ]
  }.freeze

  def subscription_badge(subscription)
    label, classes = SUBSCRIPTION_BADGES.fetch(
      subscription&.status,
      [ "무료 Trial", "bg-violet-100 text-violet-700" ]
    )

    tag.span(label, class: "inline-flex rounded-full px-3 py-1 text-sm font-semibold #{classes}")
  end

  def subscription_period_text(user, subscription)
    if subscription&.status == "active" && subscription.current_period_end.present?
      "이용 종료일: #{I18n.l(subscription.current_period_end.to_date, format: :long, locale: :ko)}"
    elsif user.trial_active?
      "무료 Trial #{user.trial_days_remaining}일 남음"
    else
      "이용 가능한 구독이 없습니다"
    end
  end
end
