# frozen_string_literal: true

module SwarmpodGem
  class Configuration
    attr_accessor :workspace, :output, :gems_dir, :port,
                  :gemfile_path, :prompts_dir, :auto_boot,
                  :clone_timeout, :max_events, :debounce_ms

    def initialize
      @workspace     = ENV.fetch("WORKSPACE", "/workspace")
      @output        = ENV.fetch("OUTPUT", "/output")
      @gems_dir      = ENV.fetch("GEMS_DIR", "/gems")
      @port          = ENV.fetch("PORT", "4000").to_i
      @gemfile_path  = ENV.fetch("SWARMPOD_GEMFILE", nil)
      @prompts_dir   = ENV.fetch("SWARMPOD_PROMPTS", nil)
      @auto_boot     = ENV.fetch("SWARMPOD_AUTO_BOOT", "true") == "true"
      @clone_timeout = ENV.fetch("SWARMPOD_CLONE_TIMEOUT", "60").to_i
      @max_events    = ENV.fetch("SWARMPOD_MAX_EVENTS", "50").to_i
      @debounce_ms   = ENV.fetch("SWARMPOD_DEBOUNCE_MS", "100").to_i
    end

    def resolved_gemfile_path
      return @gemfile_path if @gemfile_path

      # When running inside a Rails host app, look for Swarmpodfile at the app root
      if defined?(Rails) && Rails.root
        swarmpodfile = Rails.root.join("Swarmpodfile").to_s
        return swarmpodfile if File.exist?(swarmpodfile)
      end

      # Fall back to the gem's own Gemfile
      File.join(resolved_prompts_dir, "..", "Gemfile")
    end

    def resolved_prompts_dir
      @prompts_dir || File.join(SwarmpodGem.root, "prompts")
    end
  end
end
