# frozen_string_literal: true

# Refundable
module Refundable
  extend ActiveSupport::Concern

  included do
    before_update :refund_if_canceled_by_s_or_a, if: -> { canceled_by_admin? }

    def refund_if_canceled_by_s_or_a
      self.allow_refund = true
    end
  end
end
