# frozen_string_literal: true

module SwarmpodGem
  module Services
    class GemfileParser
      COLOR_PALETTE = [
        "#3b82f6", # blue
        "#22c55e", # green
        "#a855f7", # purple
        "#f59e0b", # amber
        "#ef4444", # red
        "#06b6d4", # cyan
        "#ec4899", # pink
        "#84cc16", # lime
      ].freeze

      # Parse a Gemfile and extract grouped gem declarations.
      # Returns a hash keyed by group name, each containing an array of
      # { name:, git: } hashes.
      def self.parse_gemfile(path)
        content = File.read(path)
        groups = {}

        content.scan(/group\s+:(\w+)\s+do\s*\n(.*?)^end/m) do |group_name, body|
          gems = []
          body.scan(/gem\s+"([^"]+)"(?:,\s*git:\s*"([^"]+)")?/) do |gem_name, git_url|
            gems << { name: gem_name, git: git_url }
          end
          groups[group_name] = gems
        end

        groups
      end

      # Convert parsed gem groups into agent definitions.
      # Each gem becomes an agent: id is the gem name with "-gem" stripped,
      # color is assigned from the palette, and prompt_file is "{id}.md".
      #
      # Returns { tab_id => [{ id:, color:, prompt_file:, gem_name:, git: }, ...] }
      def self.gems_to_agents(groups)
        tab_agents = {}
        color_idx = 0

        groups.each do |group_name, gems|
          tab_agents[group_name] = gems.map do |gem_info|
            id = gem_info[:name].sub(/-gem$/, "")
            color = COLOR_PALETTE[color_idx % COLOR_PALETTE.length]
            color_idx += 1
            {
              id: id,
              color: color,
              prompt_file: "#{id}.md",
              gem_name: gem_info[:name],
              git: gem_info[:git],
            }
          end
        end

        tab_agents
      end
    end
  end
end
