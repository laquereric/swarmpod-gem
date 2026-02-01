# frozen_string_literal: true

module SwarmpodGem
  module Api
    class StateController < ApplicationController
      def show
        orchestrator = Services::Orchestrator.instance
        if orchestrator
          render json: orchestrator.get_state
        else
          render json: { error: "Orchestrator not booted" }, status: 503
        end
      end
    end
  end
end
