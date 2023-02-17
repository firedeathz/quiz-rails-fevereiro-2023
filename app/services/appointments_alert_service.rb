# frozen_string_literal: true

module Services
  # NotificationsService
  class AppointmentsAlertService
    attr_reader :appointment

    def initialize(appointment)
      @appointment = appointment
    end

    def alert_status_change!
      return if appointment.is_private?

      appointment.user.user_devices.each do |d|
        Notification.send_appointment_status_change_notification(
          status_alert_message, appointment.offer_id || 1, d.device_id
        )
      end
      appointment.update(status_changed_at: Time.now) unless pending?
    end

    def alert_appointment!
      appointment.user.user_devices.each do |user_device|
        device_id = user_device.device_id
        Notification.send_appointment_alerts(appointment_alert_message, appointment.offer_id || 1, device_id)
      end
    end

    private

    def appointment_alert_message
      msg = "You have an appointment with #{stylist_name}"
      if appointment.date && appointment.time
        return "#{msg} at #{appointment.time.strftime('%H:%M')} on #{appointment.date}"
      end

      msg
    end

    def status_alert_message
      msg = "#{appointment.status}_status_alert".gsub('stylist', stylist_name)
      msg = msg.gsub('dd', appointment_date).gsub('tt', appointment_time)
      I18n.t(msg, locale: 'ur')
    end

    def appointment_date
      appointment.date ? appointment.date.strftime('%d-%m-%Y') : ''
    end

    def appointment_time
      appointment.time ? appointment.time.strftime('%l:%M %p') : ''
    end

    def stylist_name
      stylist_translations = appointment.stylist.translations.last
      "#{stylist_translations.title} #{stylist_translations.name}".strip
    end
  end
end
