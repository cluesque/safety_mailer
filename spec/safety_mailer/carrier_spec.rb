require 'spec_helper'

describe SafetyMailer::Carrier do
  let(:mail) do
    Mail.new do
      from    'safety@example.com'
      to      'mailer@example.com, pop@oozou.com'
      subject "Angry Birds Star Wars"
      body    "Lorem ipsum dolor sit amet"
    end
  end

  it "prevents mail from going out if no recipient is whitelisted" do
    Mail::SMTP.any_instance.should_not_receive(:deliver!)
    SafetyMailer::Carrier.new.deliver!(mail)
  end

  it "strips out unsafe recipients" do
    Mail::SMTP.any_instance.should_receive(:deliver!) do |mail|
      mail.to.should_not include 'mailer@example.com'
      mail.to.should     include 'pop@oozou.com'
    end.once

    SafetyMailer::Carrier.new({
      allowed_matchers: [/@oozou\.com$/]
    }).deliver!(mail)
  end

  context "with irrelevant SendGrid headers" do
    let(:mail) do
      Mail.new do
        from    'safety@example.com'
        to      'mailer@example.com, pop@oozou.com'
        subject "Angry Birds Star Wars"
        body    "Lorem ipsum dolor sit amet"
      end.tap do |m|
        m['X-SMTPAPI'] = stub(value: '{}')
      end
    end

    it "ignores SendGrid headers, strips out unsafe recipients" do
      Mail::SMTP.any_instance.should_receive(:deliver!) do |mail|
        mail.to.should_not include 'mailer@example.com'
        mail.to.should     include 'pop@oozou.com'
      end.once

      SafetyMailer::Carrier.new({
        allowed_matchers: [/@oozou\.com$/]
      }).deliver!(mail)
    end
  end

  context "with SendGrid batch mailing" do
    let(:mail) do
      Mail.new do
        from    'safety@example.com'
        subject "Lunch Order"
        body    "You like -food-"
      end.tap do |m|
        sendgrid = {
          'to'  => ['mailer@example.com', 'pop@oozou.com'],
          'sub' => { '-food-' => ['bagels', 'sushi'] }
        }
        m['X-SMTPAPI'] = JSON.generate(sendgrid)
      end
    end

    it "strips out unsafe recipients and corresponding substitutions" do
      Mail::SMTP.any_instance.should_receive(:deliver!) do |mail|
        recipients = JSON.parse(mail['X-SMTPAPI'].value)['to']
        recipients.should_not include 'mailer@example.com'
        recipients.should     include 'pop@oozou.com'

        substitutions = JSON.parse(mail['X-SMTPAPI'].value)['sub']
        substitutions['-food-'].should_not include 'bagels'
        substitutions['-food-'].should     include 'sushi'
      end.once

      SafetyMailer::Carrier.new({
        allowed_matchers: [/@oozou\.com$/]
      }).deliver!(mail)
    end
  end
end
