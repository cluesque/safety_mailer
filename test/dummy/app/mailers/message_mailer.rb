# frozen_string_literal: true

class MessageMailer < ActionMailer::Base
  default from: 'system@example.com'

  def time_notification(address)
    @current_time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    mail(
      to: address,
      subject: 'Current Time Notification'
    )
  end
end
