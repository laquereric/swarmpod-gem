# frozen_string_literal: true

require "json"

module SwarmpodGem
  module Services
    class NdjsonParser
      # Parse a single NDJSON line and apply state mutations.
      # Returns true if state was changed, false otherwise.
      def self.handle_line(state_manager, tab_id, agent_id, line)
        trimmed = line.strip
        return false if trimmed.empty?

        msg = begin
          JSON.parse(trimmed)
        rescue JSON::ParserError
          return false
        end

        agent = state_manager.get_agent(tab_id, agent_id)
        return false unless agent

        case msg["type"]
        when "system"
          if agent[:status] == "pending" || agent["status"] == "pending"
            state_manager.update_agent(tab_id, agent_id, {
              status: "starting",
              startedAt: (Time.now.to_f * 1000).to_i,
            })
            state_manager.add_event(tab_id, agent_id, "status", "Agent starting")
          end

        when "assistant"
          current_status = agent[:status] || agent["status"]
          if current_status != "running"
            state_manager.update_agent(tab_id, agent_id, { status: "running" })
            state_manager.add_event(tab_id, agent_id, "status", "Agent running")
          end

          content = msg.dig("message", "content")
          if content.is_a?(Array)
            content.each do |block|
              if block["type"] == "text" && block["text"]
                snippet = block["text"][0, 200]
                state_manager.update_agent(tab_id, agent_id, { lastActivity: snippet })
                state_manager.add_event(tab_id, agent_id, "text", snippet)
              end

              if block["type"] == "tool_use"
                tool_name = block["name"] || "unknown"
                new_counts = state_manager.increment_tool_count(tab_id, agent_id, tool_name)
                input_str = block["input"] ? JSON.generate(block["input"])[0, 100] : ""
                state_manager.update_agent(tab_id, agent_id, {
                  lastActivity: "Using tool: #{tool_name}",
                  toolCounts: new_counts,
                })
                state_manager.add_event(tab_id, agent_id, "tool_use", "#{tool_name}(#{input_str})")
              end
            end
          end

        when "result"
          started_at = agent[:startedAt] || agent["startedAt"]
          duration = if started_at
            "#{((Time.now.to_f * 1000 - started_at.to_f) / 1000).round(1)}s"
          end

          cost = msg["cost_usd"] || msg["cost"]
          cost_str = cost ? " ($#{format("%.4f", cost)})" : ""

          state_manager.update_agent(tab_id, agent_id, {
            status: "completed",
            cost: cost,
            duration: duration,
            lastActivity: "Completed",
          })
          state_manager.add_event(tab_id, agent_id, "status", "Completed#{cost_str}")

        when "tool_result"
          state_manager.add_event(tab_id, agent_id, "tool_result", "Tool returned result")

        else
          if msg["type"] == "content_block_start" || msg["type"] == "content_block_delta"
            current_status = agent[:status] || agent["status"]
            if current_status != "running"
              state_manager.update_agent(tab_id, agent_id, { status: "running" })
            end
          end
        end

        true
      end
    end
  end
end
