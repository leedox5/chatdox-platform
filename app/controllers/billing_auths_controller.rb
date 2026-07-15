class BillingAuthsController < ApplicationController
  def create
    redirect_to chatdox_path,
      alert: "신규 결제는 준비 중입니다. 기간제 라이선스 결제가 열리면 안내하겠습니다.",
      status: :see_other
  end
end
