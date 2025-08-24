# frozen_string_literal: true

require 'spec_helper'
require 'mail'

RSpec.describe SafetyMailer::Carrier do
  # rubocop:disable RSpec/VariableDefinition, RSpec/VariableName
  describe 'stubbing delivery class' do
    describe 'no recipient is whitelisted' do
      let(:mailer) { instance_double(Mail::SMTP) }

      before do
        message = Mail.new do
          from    'safety@example.com'
          to      'mailer@example.com, pop@oozou.com'
          subject 'Angry Birds Star Wars'
          body    'Lorem ipsum dolor sit amet'
        end
        allow(mailer).to receive(:deliver!)
        allow(Mail::SMTP).to receive(:new).and_return(mailer)
        described_class.new({ allowed_matchers: [/@unrelated\.com$/] }).deliver!(message)
      end

      it 'suppresses delivery altogether' do
        expect(mailer).not_to have_received(:deliver!)
      end
    end

    describe 'allowing mail to go only to some recipients' do
      let(:mailer) { instance_double(Mail::SMTP) }

      before do
        allow(mailer).to receive(:deliver!)
        allow(Mail::SMTP).to receive(:new).and_return(mailer)
        message = Mail.new do
          from    'safety@example.com'
          to      'mailer@example.com, pop@oozou.com'
          subject 'Angry Birds Star Wars'
          body    'Lorem ipsum dolor sit amet'
        end

        described_class.new({ allowed_matchers: [/@oozou\.com$/] }).deliver!(message)
      end

      it 'allows mail to go only to whitelisted recipients' do
        expect(mailer).to have_received(:deliver!) do |mail|
          expect(mail.to).not_to include 'mailer@example.com'
          expect(mail.to).to include 'pop@oozou.com'
        end
      end
    end

    context 'with irrelevant SendGrid headers' do
      let(:mailer) { instance_double(Mail::SMTP) }

      before do
        allow(mailer).to receive(:deliver!)
        allow(Mail::SMTP).to receive(:new).and_return(mailer)
        message = Mail.new do
          from    'safety@example.com'
          to      'mailer@example.com, pop@oozou.com'
          subject 'Angry Birds Star Wars'
          body    'Lorem ipsum dolor sit amet'
        end
        message['X-SMTPAPI'] = '{}'
        described_class.new(allowed_matchers: [/@oozou\.com$/]).deliver!(message)
      end

      it 'ignores SendGrid headers, strips out unsafe recipients' do
        expect(mailer).to have_received(:deliver!) do |mail|
          expect(mail.to).not_to include 'mailer@example.com'
          expect(mail.to).to include 'pop@oozou.com'
        end
      end
    end

    context 'with SendGrid batch mailing' do
      let(:mailer) { instance_double(Mail::SMTP) }

      before do
        allow(mailer).to receive(:deliver!).once
        allow(Mail::SMTP).to receive(:new).and_return(mailer)
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
        described_class.new(allowed_matchers: [/@oozou\.com$/]).deliver!(message)
      end

      it 'strips out unsafe recipients and corresponding substitutions' do
        expect(mailer).to have_received(:deliver!) do |mail|
          parsed = JSON.parse(mail['X-SMTPAPI'].value)
          recipients = parsed['to']
          expect(recipients).not_to include 'mailer@example.com'
          expect(recipients).to include 'pop@oozou.com'

          substitutions = parsed['sub']
          expect(substitutions['-food-']).not_to include 'bagels'
          expect(substitutions['-food-']).to     include 'sushi'
        end
      end
    end
  end

  it 'allows initialization with a custom delivery method' do
    expect(described_class.new(delivery_method: :faker)).to be_a described_class
  end
  # rubocop:enable RSpec/VariableDefinition, RSpec/VariableName
end
