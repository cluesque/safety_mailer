# frozen_string_literal: true

require 'test_helper'
require 'rails'

# Add the dummy app to load path
$LOAD_PATH.unshift File.expand_path('dummy', __dir__)

# Load the dummy Rails application
require_relative 'dummy/config/environment'

class IntegrationTest < Minitest::Test
  def setup
    # Clear any previous deliveries
    ActionMailer::Base.deliveries.clear

    # Use test delivery method for ActionMailer to capture emails
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true

    @original_method = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :safety_mailer
    ActionMailer::Base.safety_mailer_settings = {
      delivery_method: @original_method,
      allowed_matchers: [/@safe\.example\.com$/, /@trusted\.org$/]
    }
  end

  def delivered_messages
    ActionMailer::Base.deliveries
  end

  def test_rails_integration_allows_safe_domain_emails
    # Test that safe domain email goes through
    message = Message.new('user@safe.example.com')
    message.send_time_notification

    assert_equal 1, delivered_messages.length, 'Expected safe domain email to be delivered'
    delivered_mail = delivered_messages.first
    assert_includes delivered_mail.to, 'user@safe.example.com'
    assert_equal 'Current Time Notification', delivered_mail.subject
    assert_match(/The current time is:/, delivered_mail.body.to_s)
  ensure
    ActionMailer::Base.delivery_method = @original_method
  end

  def test_rails_integration_blocks_unsafe_domain_emails
    # Test that unsafe domain email is blocked
    message = Message.new('user@unsafe.example.com')
    message.send_time_notification

    assert_equal 0, delivered_messages.length, 'Expected unsafe domain email to be blocked'
  ensure
    ActionMailer::Base.delivery_method = @original_method
  end

  def test_rails_integration_allows_multiple_safe_domains
    # Test both allowed domains
    message1 = Message.new('user@safe.example.com')
    message1.send_time_notification

    message2 = Message.new('admin@trusted.org')
    message2.send_time_notification

    assert_equal 2, delivered_messages.length, 'Expected both safe domain emails to be delivered'

    addresses = delivered_messages.flat_map(&:to)
    assert_includes addresses, 'user@safe.example.com'
    assert_includes addresses, 'admin@trusted.org'
  ensure
    ActionMailer::Base.delivery_method = @original_method
  end
end
