module SafetyMailer
  class Railtie < Rails::Railtie
    initializer "safety_mailer.add_delivery_method" do
      ActionMailer::Base.add_delivery_method :safety_mailer, SafetyMailer::Carrier
    end
  end
end
