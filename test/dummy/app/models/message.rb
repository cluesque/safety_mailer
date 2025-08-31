# frozen_string_literal: true

class Message
  attr_reader :address

  def initialize(address)
    @address = address
  end

  def send_time_notification
    MessageMailer.time_notification(address).deliver_now
  end
end
