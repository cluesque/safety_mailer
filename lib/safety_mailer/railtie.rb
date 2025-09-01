# frozen_string_literal: true

module SafetyMailer
  # Defining a Railtie to hook into Rails initialization process
  class Railtie < Rails::Railtie
    config.before_configuration do
      ActionMailer::Base.add_delivery_method :safety_mailer, SafetyMailer::Carrier
    end
  end
end
