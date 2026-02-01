# frozen_string_literal: true

require "open3"

module SwarmpodGem
  module Services
    class AgentSpawner
      def initialize(state_manager:, prompts_dir:, workspace:, output:)
        @state_manager = state_manager
        @prompts_dir = prompts_dir
        @workspace = workspace
        @output = output
        @processes = {}
        @mutex = Mutex.new
      end

      # Spawn a Claude CLI agent process for the given tab/agent definition.
      # Reads NDJSON from stdout in a background thread.
      # Returns the spawned thread (or nil on error).
      def spawn_agent(tab_id, agent_def, user_task, &on_state_change)
        prompt_path = File.join(@prompts_dir, agent_def[:prompt_file])
        role_prompt = begin
          File.read(prompt_path)
        rescue Errno::ENOENT
          @state_manager.add_event(tab_id, agent_def[:id], "error", "Prompt file not found: #{agent_def[:prompt_file]}")
          @state_manager.update_agent(tab_id, agent_def[:id], { status: "error", lastActivity: "Missing prompt file" })
          on_state_change&.call
          return nil
        end

        prompt = "#{role_prompt}\n\nUser task: #{user_task}"

        @state_manager.update_agent(tab_id, agent_def[:id], {
          status: "starting",
          startedAt: (Time.now.to_f * 1000).to_i,
        })
        @state_manager.add_event(tab_id, agent_def[:id], "status", "Spawning agent")
        on_state_change&.call

        thread = Thread.new do
          env = ENV.to_h.merge("OUTPUT" => @output)
          cmd = [
            "claude",
            "-p", prompt,
            "--output-format", "stream-json",
            "--verbose",
            "--allowedTools", "Write",
            "--allowedTools", "Edit",
            "--allowedTools", "Read",
            "--allowedTools", "Bash",
          ]

          begin
            Open3.popen3(env, *cmd, chdir: @workspace) do |stdin, stdout, stderr, wait_thr|
              stdin.close

              @mutex.synchronize { @processes["#{tab_id}:#{agent_def[:id]}"] = wait_thr.pid }

              # Read stderr in separate thread
              stderr_thread = Thread.new do
                stderr.each_line do |line|
                  text = line.strip
                  if text.length > 0
                    @state_manager.add_event(tab_id, agent_def[:id], "stderr", text[0, 200])
                    on_state_change&.call
                  end
                end
              rescue IOError
                # stream closed
              end

              # Read NDJSON from stdout
              stdout.each_line do |line|
                NdjsonParser.handle_line(@state_manager, tab_id, agent_def[:id], line)
                on_state_change&.call
              end

              stderr_thread.join(5)
              exit_status = wait_thr.value

              agent = @state_manager.get_agent(tab_id, agent_def[:id])
              if agent && agent[:status] != "completed"
                started_at = agent[:startedAt]
                duration = if started_at
                  "#{((Time.now.to_f * 1000 - started_at.to_f) / 1000).round(1)}s"
                end

                if exit_status.success?
                  @state_manager.update_agent(tab_id, agent_def[:id], {
                    status: "completed",
                    duration: duration,
                    lastActivity: "Completed",
                  })
                  @state_manager.add_event(tab_id, agent_def[:id], "status", "Completed")
                else
                  @state_manager.update_agent(tab_id, agent_def[:id], {
                    status: "error",
                    duration: duration,
                    lastActivity: "Exited with code #{exit_status.exitstatus}",
                  })
                  @state_manager.add_event(tab_id, agent_def[:id], "status", "Error (exit code #{exit_status.exitstatus})")
                end
                on_state_change&.call
              end

              @mutex.synchronize { @processes.delete("#{tab_id}:#{agent_def[:id]}") }
            end
          rescue => e
            @state_manager.update_agent(tab_id, agent_def[:id], {
              status: "error",
              lastActivity: e.message,
            })
            @state_manager.add_event(tab_id, agent_def[:id], "error", e.message)
            on_state_change&.call
          end
        end

        thread
      end
    end
  end
end
