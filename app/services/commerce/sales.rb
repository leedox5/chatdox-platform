module Commerce
  class Sales
    def self.enabled_for?(product)
      globally_enabled? && product&.active? && product&.sale_enabled?
    end

    def self.enabled_for_code?(product_code)
      enabled_for?(Product.find_by(code: product_code))
    end

    def self.globally_enabled?
      ActiveModel::Type::Boolean.new.cast(
        ENV.fetch("LEEDOX_COMMERCE_ENABLED", "false")
      )
    end
  end
end
