module Entitlements
  class ProductAccess
    def self.allowed?(user:, product_code:, at: Time.current)
      return false unless user
      return true if licensed?(user: user, product_code: product_code, at: at)

      legacy_chatdox_enabled? && product_code.to_s == "chatdox" && user.subscribed?
    end

    def self.licensed?(user:, product_code:, at: Time.current)
      user.licenses.for_product(product_code).not_canceled.any? { |license| license.active_at?(at) }
    end

    def self.legacy_chatdox_enabled?
      ActiveModel::Type::Boolean.new.cast(
        ENV.fetch("LEEDOX_LEGACY_CHATDOX_ACCESS", "true")
      )
    end
  end
end
