# frozen_string_literal: true

require 'json'

module SafetyMailer
  # Carrier class implements a delivery method for ActionMailer
  class Carrier
    attr_accessor :matchers, :settings, :mail, :logger

    def initialize(params = {})
      self.matchers = params[:allowed_matchers] || []
      self.settings = params[:delivery_method_settings] || {}
      self.logger = determine_logger(params[:logger])
      delivery_method_name = params[:delivery_method] || :smtp
      @delivery_method = if defined?(ActionMailer)
                           ActionMailer::Base.delivery_methods[delivery_method_name].new(settings)
                         else
                           Mail::Configuration.instance.lookup_delivery_method(delivery_method_name).new(settings)
                         end
      @sendgrid_options = {}
    end

    def deliver!(mail)
      self.mail = mail
      original_recipients = recipients
      allowed = filter(original_recipients)

      log_delivery_summary(original_recipients, allowed)

      if allowed.empty?
        log 'SafetyMailer: No allowed recipients found - suppressing delivery altogether'
        return
      end

      if sendgrid?
        sendgrid_header = prepare_sendgrid_delivery(allowed)
        mail.header.fields.delete_if { |f| f.name =~ /X-SMTPAPI/i }
        mail['X-SMTPAPI'] = sendgrid_header
        log 'SafetyMailer: Updated SendGrid header with filtered recipients'
      end
      mail.to = allowed

      log "SafetyMailer: Delivering email to #{allowed.size} allowed recipient(s)"
      @delivery_method.deliver!(mail)
    end

    def whitelisted?(recipient)
      matchers.any? { |m| recipient =~ m }
    end

    def filter(addresses)
      return [] if addresses.nil? || addresses.empty?

      allowed, rejected = addresses.partition { |r| whitelisted?(r) }

      rejected.each { |addr| log "SafetyMailer: Suppressed delivery for #{addr} (no matching allowed pattern)" }
      allowed.each { |addr| log "SafetyMailer: Allowed delivery for #{addr}" }

      allowed
    end

    private

    def recipients
      sendgrid?
      sendgrid_to = @sendgrid_options['to']
      sendgrid_to.nil? || sendgrid_to.empty? ? mail.to : sendgrid_to || []
    end

    def sendgrid?
      @sendgrid ||= !!if mail['X-SMTPAPI']
                        @sendgrid_options = JSON.parse(mail['X-SMTPAPI'].value)
                      end
    rescue JSON::ParserError
      log 'SafetyMailer: Unable to parse X-SMTPAPI header - invalid JSON format'
      false
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
      if (substitutions = @sendgrid_options['sub'])
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
      return unless logger

      logger.warn(msg)
    end

    def determine_logger(custom_logger)
      return custom_logger if custom_logger
      return Rails.logger if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

      nil
    end

    def log_delivery_summary(original_recipients, allowed_recipients)
      return unless logger

      total = original_recipients.size
      allowed = allowed_recipients.size
      suppressed = total - allowed

      log "SafetyMailer: Processing #{total} recipient(s) - #{allowed} allowed, #{suppressed} suppressed"
    end
  end
end
