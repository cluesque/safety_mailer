# frozen_string_literal: true

require 'safety_mailer'
require 'pry'
require 'support/fake_mailer'
require 'action_mailer'

ActionMailer::Base.add_delivery_method :faker, FakeMailer

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
