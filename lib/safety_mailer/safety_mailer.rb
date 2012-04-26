module SafetyMailer
  class Carrier
    attr_accessor :matchers, :settings
    def initialize(params = {})
      self.matchers = params[:allowed_matchers] || []
      self.settings = params[:delivery_method_settings] || {}
      delivery_method = params[:delivery_method] || :smtp
      @delivery_method = Mail::Configuration.instance.lookup_delivery_method(delivery_method).new(settings)
    end
    def log(msg)
      Rails.logger.warn(msg) if defined?(Rails)
    end
    def deliver!(mail)
      allowed_recipient = Proc.new do |recipient|
        if matchers.any?{ |m| recipient =~ m }
          false
        else
          log "*** safety_mailer suppressing mail to #{recipient}"
          true
        end
      end

      if mail['X-SMTPAPI'] and to = JSON.parse(mail['X-SMTPAPI'].value)['to']
        if to.all?(&allowed_recipient)
          log "*** safety_mailer allowing delivery to #{to}"
          return @delivery_method.deliver!(mail)
        end
      else
        mail.to = mail.to.reject(&allowed_recipient)
        unless mail.to.empty?
          log "*** safety_mailer allowing delivery to #{mail.to}"
          return @delivery_method.deliver!(mail)
        end
      end

    rescue JSON::ParserError
      log "*** unable to parse the X-SMTPAPI header"
    ensure
      log "*** safety_mailer suppressing delivery"
    end
  end
end
