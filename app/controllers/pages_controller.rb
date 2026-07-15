class PagesController < ApplicationController
  def home
    # Static landing page: no database query required.
  end

  def chatdox
    @chatdox_product = Product.find_by(code: "chatdox")
    @chatdox_offers = @chatdox_product&.product_offers&.active&.ordered || ProductOffer.none
    @chatdox_sales_enabled = Commerce::Sales.enabled_for?(@chatdox_product) &&
      Payments::Configuration.current.checkout_ready?
  end

  def getting_started; end

  def pricing; end

  def community; end

  def login; end

  def terms; end

  def privacy; end
end
