class MypageController < ApplicationController
  before_action :authenticate_user!

  def show
    @subscription = current_user.subscription
    @completed_count = current_user.chapter_progresses.completed.count
    @total_chapters = Curriculum.all.size
  end
end
