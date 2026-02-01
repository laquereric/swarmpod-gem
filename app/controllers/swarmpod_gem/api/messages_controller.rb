# frozen_string_literal: true

module SwarmpodGem
  module Api
    class MessagesController < ApplicationController
      def create
        text = params[:text]
        unless text.is_a?(String) && text.present?
          return render json: { error: "text is required" }, status: 400
        end

        orchestrator = Services::Orchestrator.instance
        unless orchestrator
          return render json: { error: "Orchestrator not booted" }, status: 503
        end

        orchestrator.send_message(text)
        render json: { ok: true }
      end
    end
  end
end
