# frozen_string_literal: true

require "open3"
require "timeout"
require "fileutils"

module SwarmpodGem
  module Services
    class CloneManager
      def initialize(workspace: nil, gems_dir: nil, clone_timeout: nil)
        config = SwarmpodGem.configuration
        @workspace = workspace || config.workspace
        @gems_dir = gems_dir || config.gems_dir
        @clone_timeout = clone_timeout || config.clone_timeout
      end

      # Resolve where a gem can be found:
      #  1. /workspace/{gem-name}/ (already in parent repo mount)
      #  2. /gems/{gem-name}/ (previously cloned)
      #  3. nil (needs cloning)
      def resolve_gem_path(gem_name)
        workspace_path = File.join(@workspace, gem_name)
        return { path: workspace_path, status: "workspace" } if File.directory?(workspace_path)

        gems_path = File.join(@gems_dir, gem_name)
        return { path: gems_path, status: "cloned" } if File.directory?(gems_path)

        nil
      end

      # Clone a single gem repo with a timeout.
      def clone_gem(gem_name, git_url)
        dest = File.join(@gems_dir, gem_name)
        FileUtils.mkdir_p(File.dirname(dest))

        stderr_output = ""
        status = nil

        Timeout.timeout(@clone_timeout) do
          _stdout, stderr, status = Open3.capture3(
            "git", "clone", "--depth", "1", git_url, dest
          )
          stderr_output = stderr
        end

        unless status&.success?
          raise "Clone of #{gem_name} failed (exit #{status&.exitstatus}): #{stderr_output.strip}"
        end

        dest
      rescue Timeout::Error
        raise "Clone of #{gem_name} timed out after #{@clone_timeout}s"
      end

      # Ensure all gems for a tab are available locally.
      # Clones any missing gems in parallel via threads.
      def ensure_tab_gems(gems)
        resolved = []
        needs_clone = []

        gems.each do |gem_info|
          found = resolve_gem_path(gem_info[:name])
          if found
            resolved << gem_info.merge(found)
          elsif gem_info[:git]
            needs_clone << gem_info
          else
            resolved << gem_info.merge(path: nil, status: "no-source")
          end
        end

        cloned = []
        errors = []

        if needs_clone.any?
          threads = needs_clone.map do |gem_info|
            Thread.new do
              path = clone_gem(gem_info[:name], gem_info[:git])
              { gem: gem_info, path: path }
            end
          end

          threads.each do |t|
            begin
              result = t.value
              resolved << result[:gem].merge(path: result[:path], status: "cloned")
              cloned << result[:gem][:name]
            rescue => e
              errors << e.message
            end
          end
        end

        { resolved: resolved, cloned: cloned, errors: errors }
      end
    end
  end
end
