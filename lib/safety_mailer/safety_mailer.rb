module SafetyMailer
  class Carrier
    attr_accessor :allowed_matchers, :settings

    def initialize(params = {})
      self.allowed_matchers = params[:allowed_matchers] || []
      self.settings = params[:delivery_method_settings] || {}
      delivery_method = params[:delivery_method] || :smtp
      @delivery_method = Mail::Configuration.instance.lookup_delivery_method(delivery_method).new(settings)
    end

    def deliver!(mail)
      original_recipients = Array(mail.to).
        concat(Array(mail.cc)).
        concat(Array(mail.bcc))
      if original_recipients.empty?
        raise ArgumentError, "At least one recipient (To, Cc or Bcc) is required to send a message"
      end

      remove_disallowed_recipients!(mail)

      allowed_recipients = mail.to.dup.
        concat(mail.cc).
        concat(mail.bcc)

      if allowed_recipients.empty?
        log "safety_mailer: no allowed recipients. Suppressing delivery"
        mail
      else
        log "safety_mailer: allowing delivery to #{allowed_recipients}"
        log "safety_mailer: original email below:"
        @delivery_method.deliver!(mail)
      end
    end

    private

    def remove_disallowed_recipients!(mail)
      recipient_allowed = lambda { |recipient|
        allowed_matchers.any? { |m| recipient =~ m }
      }

      mail.to = Array(mail.to).select(&recipient_allowed)
      mail.cc = Array(mail.cc).select(&recipient_allowed)
      mail.bcc = Array(mail.bcc).select(&recipient_allowed)
    end

    def log(msg)
      Rails.logger.warn(msg) if defined?(Rails)
    end
  end
end
