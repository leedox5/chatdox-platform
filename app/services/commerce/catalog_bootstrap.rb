module Commerce
  class CatalogBootstrap
    PRODUCTS = {
      "chatdox" => "Chatdox",
      "claudox" => "Claudox"
    }.freeze
    CHATDOX_OFFERS = [
      { code: "chatdox-1m-v1", version: 1, duration_months: 1,
        supply_amount: 7_000, vat_amount: 700, total_amount: 7_700, discount_bps: 0 },
      { code: "chatdox-3m-v1", version: 1, duration_months: 3,
        supply_amount: 21_000, vat_amount: 2_100, total_amount: 23_100, discount_bps: 0 },
      { code: "chatdox-6m-v1", version: 1, duration_months: 6,
        supply_amount: 37_800, vat_amount: 3_780, total_amount: 41_580, discount_bps: 1_000 },
      { code: "chatdox-12m-v1", version: 1, duration_months: 12,
        supply_amount: 67_200, vat_amount: 6_720, total_amount: 73_920, discount_bps: 2_000 }
    ].freeze

    def self.call!
      ApplicationRecord.transaction do
        products = PRODUCTS.to_h do |code, name|
          product = Product.find_or_create_by!(code: code) do |record|
            record.name = name
            record.active = true
            record.sale_enabled = false
          end
          [ code, product ]
        end

        CHATDOX_OFFERS.each do |attributes|
          ProductOffer.find_or_create_by!(code: attributes.fetch(:code)) do |offer|
            offer.assign_attributes(
              attributes.merge(product: products.fetch("chatdox"), currency: "KRW", active: true)
            )
          end
        end

        products
      end
    end
  end
end
