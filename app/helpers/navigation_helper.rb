module NavigationHelper
  def primary_navigation_items
    return admin_navigation_items if current_user&.admin?
    return signed_in_navigation_items if user_signed_in?

    [ [ "문서", docs_path ] ]
  end

  def mobile_navigation_items
    return [ [ "대시보드", admin_dashboard_path ], [ "마이페이지", mypage_path ] ] if current_user&.admin?
    return [ [ "마이페이지", mypage_path ] ] if user_signed_in?

    []
  end

  private

  def admin_navigation_items
    [
      [ "대시보드", admin_dashboard_path ],
      [ "문서", docs_path ],
      [ "참조", refs_path ],
      [ "사용자관리", admin_users_path ],
      [ "마이페이지", mypage_path ]
    ]
  end

  def signed_in_navigation_items
    [
      [ "문서", docs_path ],
      [ "마이페이지", mypage_path ]
    ]
  end
end
