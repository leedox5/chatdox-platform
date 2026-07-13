class PagesController < ApplicationController
  def home
    # Static landing page: no database query required.
  end

  def chatdox
    # Preserve the original Chatdox landing content as a dedicated product page.
  end

  def getting_started; end

  def pricing; end

  def community; end

  def login; end

  def terms; end

  def privacy; end
end
