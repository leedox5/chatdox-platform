module Entitlements
  class ProductAccess
    def self.allowed?(user:, product_code:, at: Time.current)
      return false unless user

      licensed?(user: user, product_code: product_code, at: at)
    end

    def self.licensed?(user:, product_code:, at: Time.current)
      user.licenses.for_product(product_code).not_canceled.any? { |license| license.active_at?(at) }
    end
  end
end
