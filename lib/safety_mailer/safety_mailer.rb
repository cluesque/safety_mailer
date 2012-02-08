module SafetyMailer
  class Config
    @@allowed_matchers = []
    cattr_accessor :allowed_matchers
    @@delivery_method = :smtp
    cattr_accessor :delivery_method
  end
  class Carrier
    attr_accessor :params
    def initialize(params = {})
      self.params = params
    end
    def log(msg)
      Rails.logger.warn(msg) if defined?(Rails)
    end
    def deliver!(mail)
      mail.to = mail.to.reject do |recipient|
        if SafetyMailer::Config.allowed_matchers.any?{ |m| recipient =~ m }
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
        Mail::Configuration.instance.lookup_delivery_method(SafetyMailer::Config.delivery_method).deliver!(mail)
      end
    end
  end
end
