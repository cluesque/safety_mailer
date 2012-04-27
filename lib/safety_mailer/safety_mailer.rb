module SafetyMailer
  class Carrier
    attr_accessor :matchers, :settings, :mail

    def initialize(params = {})
      self.matchers = params[:allowed_matchers] || []
      self.settings = params[:delivery_method_settings] || {}
      delivery_method = params[:delivery_method] || :smtp
      @delivery_method = Mail::Configuration.instance.lookup_delivery_method(delivery_method).new(settings)
    end

    def deliver!(mail)
      self.mail = mail
      allowed = filter(recipients)

      if sendgrid?
        recipients_header = JSON.generate(sendgrid_options.merge(:to => allowed))
      else
        recipients_header = allowed
      end

      @delivery_method.deliver!(mail) if allowed.any?
    end

    private

    def recipients
      sendgrid? ? sendgrid_options['to'] : recipients_header
    end

    def sendgrid?
      !!mail['X-SMTPAPI']
    end

    def sendgrid_options
      @sendgrid_options ||= JSON.parse(recipients_header.value) if sendgrid?
    rescue JSON::ParserError
      log "*** safety_mailer was unable to parse the X-SMTPAPI header"
    end

    def recipients_header
      @recipients_header ||= sendgrid? ? mail['X-SMTPAPI'] : mail.to
    end

    def filter(addresses)
      allowed, rejected = addresses.partition { |r| whitelisted?(r) }

      if allowed.empty?
        log "*** safety_mailer - no allowed recipients ... suppressing delivery altogether"
      else
        rejected.each { |addr| log "*** safety_mailer delivery suppressed for #{addr}" }
        allowed.each { |addr| log "*** safety_mailer delivery allowed for #{addr}" }
      end

      allowed
    end

    def whitelisted?(recipient)
      matchers.any? { |m| recipient =~ m }
    end

    def log(msg)
      Rails.logger.warn(msg) if defined?(Rails)
    end

  end
end

