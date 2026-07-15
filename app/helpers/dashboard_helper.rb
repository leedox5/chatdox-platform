module DashboardHelper
  SUBSCRIPTION_BADGES = {
    "active" => [ "구독 중", "bg-emerald-100 text-emerald-700" ],
    "past_due" => [ "결제 확인 필요", "bg-amber-100 text-amber-700" ],
    "canceled" => [ "해지됨", "bg-slate-100 text-slate-700" ],
    "expired" => [ "만료됨", "bg-rose-100 text-rose-700" ],
    "pending" => [ "결제 대기", "bg-blue-100 text-blue-700" ]
  }.freeze

  def subscription_badge(user, subscription)
    if subscription.blank? && user.licensed_for?("chatdox")
      return tag.span("Chatdox 이용 중", class: "inline-flex rounded-full bg-emerald-100 px-3 py-1 text-sm font-semibold text-emerald-700")
    end

    label, classes = SUBSCRIPTION_BADGES.fetch(
      subscription&.status,
      fallback_badge(user)
    )

    tag.span(label, class: "inline-flex rounded-full px-3 py-1 text-sm font-semibold #{classes}")
  end

  def subscription_period_text(user, subscription)
    if subscription&.status == "active" && subscription.current_period_end.present?
      "이용 종료일: #{I18n.l(subscription.current_period_end.to_date, format: :long, locale: :ko)}"
    elsif (license = user.licenses.for_product("chatdox").not_canceled.find { |item| item.active_at? })
      "Chatdox 이용 종료일: #{I18n.l(license.last_usable_on, format: :long, locale: :ko)}"
    elsif user.trial_active?
      "무료 Trial #{user.trial_days_remaining}일 남음"
    else
      "이용 가능한 구독이 없습니다"
    end
  end

  private

  def fallback_badge(user)
    if user.trial_active?
      [ "무료 Trial", "bg-violet-100 text-violet-700" ]
    else
      [ "이용 불가", "bg-gray-100 text-gray-700" ]
    end
  end
end
