# frozen_string_literal: true

require 'minitest/autorun'
require 'safety_mailer'
require 'support/fake_mailer'
require 'action_mailer'

ActionMailer::Base.add_delivery_method :faker, FakeMailer
