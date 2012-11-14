module SafetyMailer
  class Carrier
    attr_accessor :matchers, :settings, :mail

    def initialize(params = {})
      self.matchers = params[:allowed_matchers] || []
      self.settings = params[:delivery_method_settings] || {}
      delivery_method = params[:delivery_method] || :smtp
      @delivery_method = Mail::Configuration.instance.lookup_delivery_method(delivery_method).new(settings)
      @sendgrid_options = {}
    end

    def deliver!(mail)
      self.mail = mail
      allowed = filter(recipients)

      if allowed.empty?
        log "*** safety_mailer - no allowed recipients ... suppressing delivery altogether"
        return
      end

      mail['X-SMTPAPI'].value = prepare_sendgrid_delivery(allowed) if sendgrid?
      mail.to = allowed

      @delivery_method.deliver!(mail)
    end

    private

    def recipients
      sendgrid?
      sendgrid_to = @sendgrid_options['to']
      sendgrid_to.nil? || sendgrid_to.empty? ? mail.to : sendgrid_to
    end

    def sendgrid?
      @sendgrid ||= !!if mail['X-SMTPAPI']
        @sendgrid_options = JSON.parse(mail['X-SMTPAPI'].value)
      end
    rescue JSON::ParserError
      log "*** safety_mailer was unable to parse the X-SMTPAPI header"
    end

    def filter(addresses)
      allowed, rejected = addresses.partition { |r| whitelisted?(r) }

      rejected.each { |addr| log "*** safety_mailer delivery suppressed for #{addr}" }
      allowed.each { |addr| log "*** safety_mailer delivery allowed for #{addr}" }

      allowed
    end

    def whitelisted?(recipient)
      matchers.any? { |m| recipient =~ m }
    end

    # Handles clean-up for additional SendGrid features that may be required
    # by changes to the recipient list. Expects the passed-in Array of
    # addresses to have been whitelist-filtered already.
    def prepare_sendgrid_delivery(addresses)
      amendments = { 'to' => addresses }

      # The SendGrid Substitution Tags feature, if used, requires that an
      # ordered Array of substitution values aligns with the Array of
      # recipients in the "to" field of the API header. If substitution key is
      # present, this filters the Arrays for each template to re-align with our
      # whitelisted addresses.
      #
      # @see http://docs.sendgrid.com/documentation/api/smtp-api/developers-guide/substitution-tags/
      if substitutions = @sendgrid_options['sub']
        substitutions.each do |template, values|
          values = recipients.zip(values).map do |addr, value|
            value if addresses.include?(addr)
          end

          substitutions[template] = values.compact
        end

        amendments['sub'] = substitutions
      end

      JSON.generate(@sendgrid_options.merge(amendments))
    end

    def log(msg)
      Rails.logger.warn(msg) if defined?(Rails)
    end

  end
end
