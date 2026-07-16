class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :dashboard, :access?

    @licenses = current_user.licenses.includes(:product).order(starts_on: :asc)
    @orders = current_user.orders.includes(:refund_requests, :payment_transaction, order_items: :license)
      .order(created_at: :desc).limit(10)
    @completed_ids = current_user.chapter_progresses
      .completed
      .order(completed_at: :desc)
      .pluck(:chapter_id)
    @total_chapters = Curriculum.all.size
    @completed_count = @completed_ids.size
    @progress_percent = progress_percent(@completed_count, @total_chapters)
    @recent_chapters = @completed_ids.first(3).filter_map { |id| Curriculum.find(id) }
    @next_chapter = Curriculum.all.find { |chapter| @completed_ids.exclude?(chapter[:id]) }
    @accessible_chapters = Curriculum.all.count do |chapter|
      current_user.can_view_chapter?(chapter[:id], product_code: "chatdox")
    end
  end

  private

  def progress_percent(completed_count, total_count)
    return 0 if total_count.zero?

    ((completed_count.to_f / total_count) * 100).round
  end
end
