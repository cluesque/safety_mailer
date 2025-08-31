# frozen_string_literal: true

require 'rails'
require 'action_mailer/railtie'

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.0

    # Configure ActionMailer
    config.action_mailer.delivery_method = :test
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true

    # Minimal configuration
    config.eager_load = false
    config.consider_all_requests_local = true
    config.cache_classes = false

    # Configure secret key base
    config.secret_key_base = 'test_key_base_for_dummy_app'
  end
end
