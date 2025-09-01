# frozen_string_literal: true

require 'test_helper'
require 'mail'
require 'json'

module SafetyMailer
  class CarrierTest < Minitest::Test
    class MockDeliveryMethod
      attr_reader :delivered_mail, :called

      def initialize
        @delivered_mail = nil
        @called = false
      end

      def deliver!(mail)
        @delivered_mail = mail
        @called = true
      end
    end

    def test_no_recipient_is_whitelisted_suppresses_delivery
      mock_delivery = MockDeliveryMethod.new
      Mail::SMTP.stub(:new, mock_delivery) do
        message = Mail.new do
          from    'safety@example.com'
          to      'mailer@example.com, pop@oozou.com'
          subject 'Angry Birds Star Wars'
          body    'Lorem ipsum dolor sit amet'
        end

        SafetyMailer::Carrier.new({ allowed_matchers: [/@unrelated\.com$/] }).deliver!(message)

        refute mock_delivery.called, 'Expected delivery to be suppressed'
      end
    end

    def test_allows_mail_to_go_only_to_whitelisted_recipients
      mock_delivery = MockDeliveryMethod.new

      Mail::SMTP.stub(:new, mock_delivery) do
        message = Mail.new do
          from    'safety@example.com'
          to      'mailer@example.com, pop@oozou.com'
          subject 'Angry Birds Star Wars'
          body    'Lorem ipsum dolor sit amet'
        end

        SafetyMailer::Carrier.new({ allowed_matchers: [/@oozou\.com$/] }).deliver!(message)

        assert mock_delivery.called, 'Expected delivery to be called'
        refute_includes mock_delivery.delivered_mail.to, 'mailer@example.com'
        assert_includes mock_delivery.delivered_mail.to, 'pop@oozou.com'
      end
    end

    def test_ignores_sendgrid_headers_strips_out_unsafe_recipients
      mock_delivery = MockDeliveryMethod.new

      Mail::SMTP.stub(:new, mock_delivery) do
        message = Mail.new do
          from    'safety@example.com'
          to      'mailer@example.com, pop@oozou.com'
          subject 'Angry Birds Star Wars'
          body    'Lorem ipsum dolor sit amet'
        end
        message['X-SMTPAPI'] = '{}'

        SafetyMailer::Carrier.new(allowed_matchers: [/@oozou\.com$/]).deliver!(message)

        assert mock_delivery.called, 'Expected delivery to be called'
        refute_includes mock_delivery.delivered_mail.to, 'mailer@example.com'
        assert_includes mock_delivery.delivered_mail.to, 'pop@oozou.com'
      end
    end

    def test_strips_out_unsafe_recipients_and_corresponding_substitutions
      mock_delivery = MockDeliveryMethod.new

      Mail::SMTP.stub(:new, mock_delivery) do
        message = Mail.new do
          from    'safety@example.com'
          subject 'Lunch Order'
          body    'You like -food-'
        end
        sendgrid = {
          'to' => ['mailer@example.com', 'pop@oozou.com'],
          'sub' => { '-food-' => %w[bagels sushi] }
        }
        message['X-SMTPAPI'] = JSON.generate(sendgrid)

        SafetyMailer::Carrier.new(allowed_matchers: [/@oozou\.com$/]).deliver!(message)

        assert mock_delivery.called, 'Expected delivery to be called'
        parsed = JSON.parse(mock_delivery.delivered_mail['X-SMTPAPI'].value)
        recipients = parsed['to']
        refute_includes recipients, 'mailer@example.com'
        assert_includes recipients, 'pop@oozou.com'

        substitutions = parsed['sub']
        refute_includes substitutions['-food-'], 'bagels'
        assert_includes substitutions['-food-'], 'sushi'
      end
    end

    def test_allows_initialization_with_custom_delivery_method
      carrier = SafetyMailer::Carrier.new(delivery_method: :faker)
      assert_instance_of SafetyMailer::Carrier, carrier
    end
  end
end
