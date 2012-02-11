module SafetyMailer
  class Railtie < Rails::Railtie
    config.before_configuration do
      ActionMailer::Base.add_delivery_method :safety_mailer, SafetyMailer::Carrier
    end
  end
end
