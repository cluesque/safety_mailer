# frozen_string_literal: true

require 'test_helper'
require 'logger'
require 'stringio'

class LoggerTest < Minitest::Test
  def setup
    @log_output = StringIO.new
    @custom_logger = Logger.new(@log_output)
    @custom_logger.level = Logger::WARN
  end

  def test_uses_custom_logger_when_provided
    carrier = SafetyMailer::Carrier.new(
      logger: @custom_logger,
      allowed_matchers: [/@safe\.com$/]
    )

    assert_equal @custom_logger, carrier.logger
  end

  def test_defaults_to_rails_logger_when_available
    # Skip this test if Rails is already defined from integration tests
    skip 'Rails already defined' if defined?(Rails)

    # Mock Rails.logger using stub
    rails_logger = Logger.new(StringIO.new)
    rails_mock = Class.new do
      def self.logger
        rails_logger
      end

      def self.respond_to?(method)
        method == :logger
      end
    end

    Object.const_set(:Rails, rails_mock)

    carrier = SafetyMailer::Carrier.new(allowed_matchers: [/@safe\.com$/])
    assert_equal rails_logger, carrier.logger
  ensure
    Object.send(:remove_const, :Rails) if defined?(Rails) && Rails.class.name.include?('Class')
  end

  def test_defaults_to_nil_when_no_logger_available
    # Skip if Rails is defined and can't be safely removed
    skip 'Rails defined from other tests' if defined?(Rails) && !Rails.class.name.include?('Class')

    # Temporarily remove Rails if it's our mock
    had_rails = defined?(Rails)
    Object.send(:remove_const, :Rails) if had_rails && Rails.class.name.include?('Class')

    carrier = SafetyMailer::Carrier.new(allowed_matchers: [/@safe\.com$/])
    assert_nil carrier.logger
  end

  def test_logs_delivery_summary
    carrier = SafetyMailer::Carrier.new(
      logger: @custom_logger,
      allowed_matchers: [/@safe\.com$/],
      delivery_method: :faker
    )

    message = Mail.new do
      from 'sender@example.com'
      to 'user@safe.com, blocked@unsafe.com'
      subject 'Test Email'
      body 'Hello'
    end

    carrier.deliver!(message)

    log_content = @log_output.string
    assert_match(/SafetyMailer: Processing 2 recipient\(s\) - 1 allowed, 1 suppressed/, log_content)
  end

  def test_logs_allowed_recipients
    carrier = SafetyMailer::Carrier.new(
      logger: @custom_logger,
      allowed_matchers: [/@safe\.com$/],
      delivery_method: :faker
    )

    message = Mail.new do
      from 'sender@example.com'
      to 'user@safe.com'
      subject 'Test Email'
      body 'Hello'
    end

    carrier.deliver!(message)

    log_content = @log_output.string
    assert_match(/SafetyMailer: Allowed delivery for user@safe\.com/, log_content)
  end

  def test_logs_suppressed_recipients
    carrier = SafetyMailer::Carrier.new(
      logger: @custom_logger,
      allowed_matchers: [/@safe\.com$/],
      delivery_method: :faker
    )

    message = Mail.new do
      from 'sender@example.com'
      to 'blocked@unsafe.com'
      subject 'Test Email'
      body 'Hello'
    end

    carrier.deliver!(message)

    log_content = @log_output.string
    assert_match(/SafetyMailer: Suppressed delivery for blocked@unsafe\.com \(no matching allowed pattern\)/,
                 log_content)
  end

  def test_logs_when_no_recipients_allowed
    carrier = SafetyMailer::Carrier.new(
      logger: @custom_logger,
      allowed_matchers: [/@safe\.com$/],
      delivery_method: :faker
    )

    message = Mail.new do
      from 'sender@example.com'
      to 'blocked@unsafe.com'
      subject 'Test Email'
      body 'Hello'
    end

    carrier.deliver!(message)

    log_content = @log_output.string
    assert_match(/SafetyMailer: No allowed recipients found - suppressing delivery altogether/, log_content)
  end

  def test_logs_sendgrid_header_processing
    carrier = SafetyMailer::Carrier.new(
      logger: @custom_logger,
      allowed_matchers: [/@safe\.com$/],
      delivery_method: :faker
    )

    message = Mail.new do
      from 'sender@example.com'
      to 'user@safe.com'
      subject 'Test Email'
      body 'Hello'
    end
    message['X-SMTPAPI'] = '{"to": ["user@safe.com"]}'

    carrier.deliver!(message)

    log_content = @log_output.string
    assert_match(/SafetyMailer: Updated SendGrid header with filtered recipients/, log_content)
  end

  def test_logs_sendgrid_json_parse_error
    carrier = SafetyMailer::Carrier.new(
      logger: @custom_logger,
      allowed_matchers: [/@safe\.com$/],
      delivery_method: :faker
    )

    message = Mail.new do
      from 'sender@example.com'
      to 'user@safe.com'
      subject 'Test Email'
      body 'Hello'
    end
    message['X-SMTPAPI'] = 'invalid json'

    carrier.deliver!(message)

    log_content = @log_output.string
    assert_match(/SafetyMailer: Unable to parse X-SMTPAPI header - invalid JSON format/, log_content)
  end

  def test_no_logging_when_logger_is_nil
    carrier = SafetyMailer::Carrier.new(
      logger: nil,
      allowed_matchers: [/@safe\.com$/],
      delivery_method: :faker
    )

    message = Mail.new do
      from 'sender@example.com'
      to 'user@safe.com'
      subject 'Test Email'
      body 'Hello'
    end

    # This should not raise an error despite no logger
    begin
      carrier.deliver!(message)
      assert true, 'Delivery completed without error'
    rescue StandardError => e
      flunk "Expected no error but got: #{e.message}"
    end
  end
end
