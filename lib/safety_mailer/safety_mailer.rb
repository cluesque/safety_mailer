module SafetyMailer
  class Carrier
    attr_accessor :params
    def initialize(params = {})
      self.params = params
      delivery_method = params[:delivery_method]
      settings = params[:delivery_method_settings]
      @delivery_method = Mail::Configuration.instance.lookup_delivery_method(delivery_method).new(settings)
    end
    def log(msg)
      Rails.logger.warn(msg) if defined?(Rails)
    end
    def deliver!(mail)
      mail.to = mail.to.reject do |recipient|
        if params[:allowed_matchers].any?{ |m| recipient =~ m }
          false
        else
          log "*** safety_mailer suppressing mail to #{recipient}"
          true
        end
      end
      if mail.to.nil? || mail.to.empty?
        log "*** safety_mailer - no recipients left ... suppressing delivery altogether"
      else
        log "*** safety_mailer allowing delivery to #{mail.to}"
        @delivery_method.deliver!(mail)
      end
    end
  end
end
