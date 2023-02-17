# frozen_string_literal: true

# Appointment
class Appointment < ApplicationRecord
  include HasBarcode

  enum :status, %i[pending confirmed canceled rescheduled]

  scope :pending, -> { where(status: :pending) }
  scope :rescheduled, -> { where(status: :rescheduled) }
  scope :canceled, -> { where(status: :canceled) }
  scope :confirmed, -> { where(status: :confirmed) }

  belongs_to :offer
  belongs_to :stylist
  belongs_to :user

  validates :user_id, :offer_id, presence: true
  validates_uniqueness_of :time, scope: %i[offer_id date],
                                 conditions: -> { where.not(status: %i[canceled rescheduled]) },
                                 if: proc { |a| a.date and a.time }

  before_validation :appointment_date_time
  before_create :add_initial_call_status

  before_update :status_change_alert
  before_update :refund_if_canceled_by_s_or_a

  after_create :alert_status_change, if: -> { pending? && date.present? }
  before_update :alert_status_change, if: -> { status_changed? }

  def alert_status_change
    Services::AppointmentsAlertService.new(self).notify_status_change!
  end

  def alert_type_column(alert_type)
    case alert_type
    when 1
      :is_1_hour
    when 12
      :is_12_hour
    when 24
      :is_24_hour
    end
  end

  def appointment_date_time
    return if date_time.blank?

    self.date = date_time.to_date
    self.time = date_time.to_time.strftime('%H:%M')
  end

  def add_initial_call_status
    self.call_status = 'not called'
  end

  def toggle_call_status
    self.call_status =
      case call_status
      when 'not called'
        'called'
      when 'called'
        'no answer'
      else
        'not called'
      end
    save
  end
end
