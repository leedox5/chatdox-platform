module DashboardHelper
  def subscription_badge(user)
    label, classes = if user.licensed_for?("chatdox")
      [ "Chatdox 이용 중", "bg-emerald-100 text-emerald-700" ]
    elsif user.trial_active?
      [ "무료 Trial", "bg-violet-100 text-violet-700" ]
    else
      [ "이용 불가", "bg-gray-100 text-gray-700" ]
    end

    tag.span(label, class: "inline-flex rounded-full px-3 py-1 text-sm font-semibold #{classes}")
  end

  def subscription_period_text(user)
    if (license = user.licenses.for_product("chatdox").not_canceled.find { |item| item.active_at? })
      "Chatdox 이용 종료일: #{I18n.l(license.last_usable_on, format: :long, locale: :ko)}"
    elsif user.trial_active?
      "무료 Trial #{user.trial_days_remaining}일 남음"
    else
      "이용 가능한 라이선스가 없습니다"
    end
  end
end
