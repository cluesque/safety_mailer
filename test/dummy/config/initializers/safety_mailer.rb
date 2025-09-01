# frozen_string_literal: true

# Configure SafetyMailer for the dummy Rails app
ActionMailer::Base.add_delivery_method :safety_mailer, SafetyMailer::Carrier, {
  allowed_matchers: [/@safe\.example\.com$/, /@trusted\.org$/]
}

# Use SafetyMailer as the delivery method
ActionMailer::Base.delivery_method = :safety_mailer
