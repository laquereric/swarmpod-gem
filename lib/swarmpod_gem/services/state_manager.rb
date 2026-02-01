# frozen_string_literal: true

require "monitor"
require "json"

module SwarmpodGem
  module Services
    class StateManager
      include MonitorMixin

      attr_reader :tabs, :active_tab, :tab_agents, :tab_events, :messages

      def initialize(gem_groups:, agent_defs:, max_events: 50)
        super() # MonitorMixin
        @gem_groups = gem_groups
        @agent_defs = agent_defs
        @max_events = max_events

        tab_ids = gem_groups.keys
        @tabs = {}
        @active_tab = tab_ids.first || "web"
        @tab_agents = {}
        @tab_events = {}
        @messages = []

        tab_ids.each_with_index do |tab_id, idx|
          gems = gem_groups[tab_id]
          @tabs[tab_id] = {
            status: idx == 0 ? "ready" : "pending",
            gems: gems,
            gemCount: gems.length,
          }
          @tab_agents[tab_id] = {}
          @tab_events[tab_id] = []
        end

        reset_agents(tab_ids.first) if tab_ids.any?
      end

      def get_state
        synchronize do
          {
            tabs: deep_copy(@tabs),
            activeTab: @active_tab,
            tabAgents: deep_copy(@tab_agents),
            tabEvents: deep_copy(@tab_events),
            messages: deep_copy(@messages),
          }
        end
      end

      def set_active_tab(tab_id)
        synchronize { @active_tab = tab_id }
      end

      def get_tab_status(tab_id)
        synchronize { @tabs.dig(tab_id, :status) }
      end

      def set_tab_status(tab_id, status)
        synchronize { @tabs[tab_id][:status] = status if @tabs[tab_id] }
      end

      def reset_agents(tab_id)
        synchronize do
          agents = @agent_defs[tab_id] || []
          @tab_agents[tab_id] = {}
          agents.each do |agent|
            @tab_agents[tab_id][agent[:id]] = {
              id: agent[:id],
              color: agent[:color],
              status: "pending",
              toolCounts: {},
              lastActivity: nil,
              cost: nil,
              duration: nil,
              startedAt: nil,
            }
          end
        end
      end

      def update_agent(tab_id, agent_id, updates)
        synchronize do
          agents = @tab_agents[tab_id]
          return unless agents && agents[agent_id]
          agents[agent_id].merge!(updates)
        end
      end

      def get_agent(tab_id, agent_id)
        synchronize do
          @tab_agents.dig(tab_id, agent_id)&.dup
        end
      end

      def add_event(tab_id, agent_id, type, detail)
        synchronize do
          events = @tab_events[tab_id]
          return unless events

          events << {
            agentId: agent_id,
            type: type,
            detail: detail,
            timestamp: (Time.now.to_f * 1000).to_i,
          }

          agent_count = (@agent_defs[tab_id]&.length || 3)
          max_count = @max_events * agent_count
          if events.length > max_count
            @tab_events[tab_id] = events.last(max_count)
          end
        end
      end

      def add_message(role, text)
        synchronize do
          @messages << {
            role: role,
            text: text,
            timestamp: (Time.now.to_f * 1000).to_i,
          }
        end
      end

      def increment_tool_count(tab_id, agent_id, tool_name)
        synchronize do
          agent = @tab_agents.dig(tab_id, agent_id)
          return unless agent
          agent[:toolCounts][tool_name] = (agent[:toolCounts][tool_name] || 0) + 1
          agent[:toolCounts].dup
        end
      end

      private

      def deep_copy(obj)
        JSON.parse(JSON.generate(obj), symbolize_names: false)
      end
    end
  end
end
