# frozen_string_literal: true

module SwarmpodGem
  class DashboardChannel < ApplicationCable::Channel
    def subscribed
      stream_from "swarmpod_dashboard"

      # Send initial state on connection
      orchestrator = Services::Orchestrator.instance
      transmit(orchestrator.get_state) if orchestrator
    end

    def unsubscribed
      # cleanup if needed
    end
  end
end
