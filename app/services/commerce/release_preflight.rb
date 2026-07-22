module Commerce
  class ReleasePreflight
    Check = Data.define(:name, :status, :detail)
    Report = Data.define(:checks, :checked_at) do
      def ready_for_sandbox?
        checks.none? { |check| %w[failed blocked].include?(check.status) }
      end
    end

    def self.call(provider: ENV["PAYMENT_PROVIDER"], at: Time.current)
      new(provider: provider, at: at).call
    end

    def initialize(provider:, at:)
      @provider = provider.to_s
      @at = at
    end

    def call
      configuration = Payments::Configuration.new(provider: @provider)
      chatdox = Product.find_by(code: "chatdox")
      claudox = Product.find_by(code: "claudox")
      checks = [
        check("migration", migrations_current?, "schema is current"),
        check("catalog_products", Product.where(code: %w[chatdox claudox]).count == 2, "expected product codes exist"),
        check("chatdox_offers", chatdox&.product_offers&.count == 4, "expected four offers"),
        check("global_sale_gate", !Commerce::Sales.globally_enabled?, "must remain disabled before approval"),
        check("chatdox_sale_gate", chatdox.present? && !chatdox.sale_enabled?, "must remain disabled before approval"),
        check("claudox_sale_gate", claudox.present? && !claudox.sale_enabled?, "sale disabled before approval"),
        runtime_provider_check,
        configuration_check(configuration),
        check("callback_routes", callback_routes_present?, "callback and webhook routes recognized")
      ]
      Report.new(checks: checks.freeze, checked_at: @at)
    end

    private

    def check(name, passed, detail)
      Check.new(name: name, status: passed ? "passed" : "failed", detail: detail)
    end

    def configuration_check(configuration)
      if configuration.ready?
        Check.new(name: "provider_configuration", status: "passed", detail: "#{@provider} required environment variables present")
      else
        Check.new(
          name: "provider_configuration",
          status: "blocked",
          detail: "missing environment variables: #{configuration.missing_keys.join(',')}"
        )
      end
    end

    def runtime_provider_check
      runtime_provider = ENV["PAYMENT_PROVIDER"]
      passed = @provider.present? && runtime_provider.present? && @provider == runtime_provider && @provider == "portone"
      detail = passed ? "runtime and preflight provider are explicitly portone" : "runtime and preflight provider must match explicit portone"
      check("runtime_provider", passed, detail)
    end

    def migrations_current?
      ActiveRecord::Migration.check_all_pending!
      true
    rescue ActiveRecord::PendingMigrationError
      false
    end

    def callback_routes_present?
      routes = Rails.application.routes.url_helpers
      [
        routes.billing_success_path,
        routes.billing_cancel_path,
        routes.webhooks_portone_path
      ].all?(&:present?)
    end
  end
end
