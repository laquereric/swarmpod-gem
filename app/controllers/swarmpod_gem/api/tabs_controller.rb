# frozen_string_literal: true

module SwarmpodGem
  module Api
    class TabsController < ApplicationController
      def index
        orchestrator = Services::Orchestrator.instance
        unless orchestrator
          return render json: { error: "Orchestrator not booted" }, status: 503
        end

        state = orchestrator.get_state
        tabs = (state[:tabs] || {}).map do |id, tab|
          {
            id: id,
            status: tab["status"],
            gemCount: tab["gemCount"],
            agents: (state[:tabAgents]&.dig(id) || {}).keys,
          }
        end
        render json: tabs
      end

      def activate
        orchestrator = Services::Orchestrator.instance
        unless orchestrator
          return render json: { error: "Orchestrator not booted" }, status: 503
        end

        result = orchestrator.activate_tab(params[:id])
        if result[:error]
          render json: result, status: 500
        else
          render json: result
        end
      end
    end
  end
end
