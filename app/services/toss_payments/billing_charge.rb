module TossPayments
  class BillingCharge
    def self.charge!(billing_key:, customer_key:, amount:, order_name:)
      TossPayments::Client.post_json(
        "/v1/billing/#{billing_key}",
        {
          customerKey: customer_key,
          amount: amount,
          orderId: "renewal-#{Time.current.to_i}",
          orderName: order_name
        }
      )
    end
  end
end
