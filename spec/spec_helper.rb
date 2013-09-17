require 'rubygems'
require 'bundler/setup'
require 'safety_mailer'
require 'action_mailer'
require 'mail'
require 'json'
require 'support/fake_mailer'

ActionMailer::Base.add_delivery_method :faker, FakeMailer

RSpec.configure do |config|
end
