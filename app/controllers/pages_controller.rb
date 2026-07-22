class PagesController < ApplicationController
  # Short one-line taglines for the /pricing summary cards -- Product has no
  # column for this (and doesn't need one for two products), so it's kept as
  # a plain hash next to the controller that renders it, same pattern as
  # Commerce::CatalogBootstrap::PRODUCTS. Add one line per new product.
  PRODUCT_TAGLINES = {
    "chatdox" => "AI와 함께 SaaS를 기획부터 배포까지 직접 만들어보는 실전 커리큘럼",
    "claudox" => "Claude를 팀에 합류시켜 실제로 협업한 기록을 그대로 따라가는 콘텐츠"
  }.freeze

  # Route helper name for each product's own detail page. A product with no
  # entry here just gets no "자세히 보기" link on its card -- expected for a
  # brand-new product before its landing page actually exists yet.
  PRODUCT_DETAIL_PATH_HELPERS = {
    "chatdox" => :chatdox_path,
    "claudox" => :claudox_path
  }.freeze

  def home
    # Static landing page: no database query required.
  end

  def chatdox
    # Pricing is rendered by shared/_product_pricing, which looks up the
    # product/offers/sales-enabled state itself from product_code alone.
  end

  def getting_started; end

  def pricing
    @products = Product.order(:code)
  end

  def community; end

  def login; end

  def terms; end

  def privacy; end
end
