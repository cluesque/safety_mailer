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

  it "strips out unsafe recipients" do
    Mail::SMTP.any_instance.should_receive(:deliver!) do |mail|
      mail.to.should_not include 'mailer@example.com'
      mail.to.should     include 'pop@oozou.com'
    end.once
    SafetyMailer::Carrier.new({
      allowed_matchers: [/@oozou\.com$/]
    }).deliver!(mail)
  end

  it "prevents mail from going out if no recipient is whitelisted" do
    Mail::SMTP.any_instance.should_not_receive(:deliver!)
    SafetyMailer::Carrier.new.deliver!(mail)
  end
end
