# frozen_string_literal: true

module Services
  # BroadcastAlertsService
  class BroadcastAlertsService
    class << self
      def send_alerts
        users_to_alert.each do |user|
          next if user.alert_setting.blank?

          time =
            if user.alert_setting.is_alert_1_hour? then 1
            elsif user.alert_setting.is_alert_12_hour? then 12
            elsif user.alert_setting.is_alert_24_hour? then 24
            end
          final_time = (curr_time + time.hours).strftime('2000-01-01 %H:%M:00')
          send_user_appointment_alert(user, final_time, time)
        end
      end

      private

      def send_user_appointment_alert(user, alert_time, alert_type)
        params = [true, alert_time, alert_time.to_date, :confirmed, false]
        column = alert_type_column(alert_type)
        appointments = user.appointments
                           .where("is_alert= ? AND time = ? AND date = ? AND status = ? AND #{column} = ?", *params)

        appointments.each do |app|
          ApplicationRecord.transaction do
            AppointmentsAlertService.new(app).alert_appointment!
            appointment.update(column => true)
          end
        end
      end

      def users_to_alert
        curr_time = Time.now.in_time_zone('Asia/Karachi')
        params = [true, curr_time, curr_time.to_date, :confirmed]
        Appointment.includes(:user)
                   .where('is_alert = ? AND time >= ? AND date >= ? AND status = ?', *params)
                   .map(&:user).compact.uniq
      end
    end
  end
end
