# frozen_string_literal: true

require 'safety_mailer'

RSpec.describe SafetyMailer do
  it 'has a version number' do
    expect(SafetyMailer::VERSION).not_to be nil
  end
end
