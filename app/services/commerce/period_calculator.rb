module Commerce
  class PeriodCalculator
    KST = ActiveSupport::TimeZone["Asia/Seoul"]
    Result = Data.define(:starts_on, :last_usable_on, :access_ends_at)

    def self.call(start_on:, duration_months:)
      new(start_on: start_on, duration_months: duration_months).call
    end

    def self.validate_start!(start_on:, purchased_at: Time.current)
      start_on = start_on.to_date
      purchase_date = purchased_at.in_time_zone(KST).to_date
      return start_on if (purchase_date..(purchase_date + 7.days)).cover?(start_on)

      raise ArgumentError, "start date must be between the KST purchase date and 7 days later"
    end

    def initialize(start_on:, duration_months:)
      @start_on = start_on.to_date
      @duration_months = Integer(duration_months)
      raise ArgumentError, "duration must be positive" unless @duration_months.positive?
    end

    def call
      target_month = @start_on.beginning_of_month.advance(months: @duration_months)
      last_usable_on = if @start_on.day > target_month.end_of_month.day
        target_month.end_of_month
      else
        target_month.change(day: @start_on.day) - 1.day
      end
      end_date = last_usable_on + 1.day

      Result.new(
        starts_on: @start_on,
        last_usable_on: last_usable_on,
        access_ends_at: KST.local(end_date.year, end_date.month, end_date.day)
      )
    end
  end
end
