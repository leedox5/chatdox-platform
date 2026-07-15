module Commerce
  class RetryOrder
    class Unavailable < StandardError; end

    def self.current_offer(source_order, at: Time.current)
      source_item = source_order.order_items.first!
      source_item.product.product_offers.active
        .where(duration_months: source_item.duration_months)
        .order(version: :desc).detect { |candidate| candidate.available_at?(at) }
    end

    def self.call!(source_order:, user:, provider:, at: Time.current)
      ApplicationRecord.transaction do
        source_order.lock!
        raise Pundit::NotAuthorizedError unless source_order.user_id == user.id
        raise Unavailable, "paid orders cannot be retried" if source_order.status == "paid"

        eligible = source_order.status == "abandoned" ||
          (source_order.status == "pending" && Commerce::PendingOrderAssessment.call(order: source_order, at: at).safe_to_abandon)
        raise Unavailable, "order is not safely retryable" unless eligible

        existing = source_order.retry_order
        return existing if existing

        source_item = source_order.order_items.first!
        offer = current_offer(source_order, at: at)
        raise Unavailable, "current offer is not available" unless offer

        retry_order = Commerce::OrderCreator.call!(
          user: user,
          product_code: source_item.product_code,
          offer_code: offer.code,
          requested_start_on: nil,
          provider: provider,
          retry_of_order: source_order,
          at: at
        )
        Commerce::AuditRecorder.record!(
          actor: user,
          action: "retry_order_created",
          auditable: retry_order,
          from_state: source_order.status,
          to_state: retry_order.status,
          reason_code: "new_order_from_retry",
          at: at
        )
        retry_order
      end
    rescue ActiveRecord::RecordNotUnique
      source_order.reload.retry_order || raise
    end
  end
end
