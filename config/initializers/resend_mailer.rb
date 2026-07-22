require Rails.root.join("app/mailers/delivery_methods/resend_api")

# The settings hash has to be passed here rather than via
# `config.action_mailer.resend_api_settings` in config/environments/*.rb --
# ActionMailer applies environment config to ActionMailer::Base before this
# initializer runs, and the `resend_api_settings=` writer doesn't exist until
# add_delivery_method defines it.
ActionMailer::Base.add_delivery_method(
  :resend_api,
  DeliveryMethods::ResendApi,
  api_key: ENV.fetch("RESEND_API_KEY", nil)
)
