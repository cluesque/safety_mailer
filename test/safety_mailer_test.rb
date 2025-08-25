# frozen_string_literal: true

require 'test_helper'

class SafetyMailerTest < Minitest::Test
  def test_has_version_number
    refute_nil SafetyMailer::VERSION
  end
end
