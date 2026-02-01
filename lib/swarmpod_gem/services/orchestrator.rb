# frozen_string_literal: true

module SwarmpodGem
  module Services
    class Orchestrator
      attr_reader :state_manager, :clone_manager, :agent_spawner, :debouncer,
                  :gem_groups, :agent_defs

      def initialize
        config = SwarmpodGem.configuration
        gemfile_path = config.resolved_gemfile_path
        prompts_dir = config.resolved_prompts_dir

        @gem_groups = GemfileParser.parse_gemfile(gemfile_path)
        @agent_defs = GemfileParser.gems_to_agents(@gem_groups)

        @state_manager = StateManager.new(
          gem_groups: @gem_groups,
          agent_defs: @agent_defs,
          max_events: config.max_events,
        )

        @clone_manager = CloneManager.new(
          workspace: config.workspace,
          gems_dir: config.gems_dir,
          clone_timeout: config.clone_timeout,
        )

        @agent_spawner = AgentSpawner.new(
          state_manager: @state_manager,
          prompts_dir: prompts_dir,
          workspace: config.workspace,
          output: config.output,
        )

        @debouncer = BroadcastDebouncer.new(delay_ms: config.debounce_ms) do
          broadcast_state
        end
      end

      def get_state
        @state_manager.get_state
      end

      def activate_tab(tab_id)
        return { error: "Unknown tab" } unless @state_manager.tabs.key?(tab_id)

        @state_manager.set_active_tab(tab_id)

        status = @state_manager.get_tab_status(tab_id)
        if status == "ready" || status == "loading"
          agents = @state_manager.tab_agents[tab_id] || {}
          @state_manager.reset_agents(tab_id) if agents.empty?
          schedule_broadcast
          return { status: status }
        end

        # Mark as loading and clone gems
        @state_manager.set_tab_status(tab_id, "loading")
        @state_manager.add_event(tab_id, "system", "status", "Cloning gems...")
        schedule_broadcast

        Thread.new do
          begin
            gems = @gem_groups[tab_id] || []
            result = @clone_manager.ensure_tab_gems(gems)

            if result[:errors].any?
              @state_manager.set_tab_status(tab_id, "error")
              @state_manager.add_event(tab_id, "system", "error", result[:errors].join("; "))
            else
              @state_manager.set_tab_status(tab_id, "ready")
              @state_manager.add_event(tab_id, "system", "status", "Gems ready (#{result[:cloned].length} cloned)")
            end

            @state_manager.reset_agents(tab_id)
            schedule_broadcast
          rescue => e
            @state_manager.set_tab_status(tab_id, "error")
            @state_manager.add_event(tab_id, "system", "error", e.message)
            schedule_broadcast
          end
        end

        { status: "loading" }
      end

      def send_message(text)
        tab_id = @state_manager.active_tab

        status = @state_manager.get_tab_status(tab_id)
        return unless status == "ready"

        @state_manager.add_message("user", text)
        @state_manager.add_event(tab_id, "user", "message", text)

        @state_manager.reset_agents(tab_id)
        schedule_broadcast

        agents = @agent_defs[tab_id] || []
        agents.each do |agent_def|
          @agent_spawner.spawn_agent(tab_id, agent_def, text) do
            schedule_broadcast
          end
        end
      end

      def schedule_broadcast
        @debouncer.schedule
      end

      def shutdown
        @debouncer.stop
      end

      private

      def broadcast_state
        state = get_state
        if defined?(ActionCable)
          ActionCable.server.broadcast("swarmpod_dashboard", state)
        end
      end

      class << self
        attr_accessor :instance

        def boot!
          @instance ||= new
        end

        def reset!
          @instance&.shutdown
          @instance = nil
        end
      end
    end
  end
end
