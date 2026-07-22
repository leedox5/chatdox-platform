class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :dashboard, :access?

    @completed_ids = current_user.chapter_progresses
      .completed
      .order(completed_at: :desc)
      .pluck(:chapter_id)
    @total_chapters = Curriculum.all.size
    @completed_count = @completed_ids.size
    @progress_percent = progress_percent(@completed_count, @total_chapters)
    @recent_chapters = @completed_ids.first(3).filter_map { |id| Curriculum.find(id) }
    @next_chapter = Curriculum.all.find { |chapter| @completed_ids.exclude?(chapter[:id]) }
    @accessible_chapter_stats = accessible_chapter_stats
  end

  private

  # Chatdox's ChapterProgress-based progress bar/recent-chapters/next-step
  # stay Chatdox-only this round (see request_r2.md's exclusions -- whether
  # Claudox has its own per-product progress tracking is a separate,
  # bigger investigation). This stat is simpler: just "how many of this
  # product's chapters am I currently allowed to open", which is already
  # product-agnostic via User#can_view_chapter?.
  def accessible_chapter_stats
    Product.order(:code).map do |product|
      total = chapter_total_for(product.code)
      { product: product, accessible: accessible_chapter_count(product.code, total), total: total }
    end
  end

  def chapter_total_for(product_code)
    case product_code
    when "chatdox" then Curriculum.all.size
    when "claudox" then Claudox::PHASES.sum { |phase| phase[:range].size }
    else 0
    end
  end

  # Equivalent to counting how many chapters 1..total pass
  # current_user.can_view_chapter?, but computed directly instead of
  # calling it in a loop -- access is monotonic in chapter number (whichever
  # tier applies unlocks a fixed prefix of chapters), and re-querying
  # licenses per chapter would mean up to `total` extra queries per product.
  def accessible_chapter_count(product_code, total)
    return total if current_user.admin? || current_user.licensed_for?(product_code)
    return [ total, 5 ].min if current_user.trial_active?

    [ total, 2 ].min
  end

  def progress_percent(completed_count, total_count)
    return 0 if total_count.zero?

    ((completed_count.to_f / total_count) * 100).round
  end
end
