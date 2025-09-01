# frozen_string_literal: true

class FakeMailer
  def initialize(options = {}); end

  def deliver!(mail)
    # Simulate delivery - do nothing but don't error
  end
end
