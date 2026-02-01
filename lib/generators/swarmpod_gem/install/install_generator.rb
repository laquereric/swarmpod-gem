# frozen_string_literal: true

require "rails/generators/base"

module SwarmpodGem
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install SwarmpodGem: mount engine, create config, and set up directories"

      class_option :mount_path, type: :string, default: "/swarmpod",
        desc: "Path to mount the SwarmpodGem engine at"

      def mount_engine
        route_line = "mount SwarmpodGem::Engine => \"#{options[:mount_path]}\""

        if File.exist?(routes_path) && File.read(routes_path).include?("SwarmpodGem::Engine")
          say_status :skip, "Engine already mounted in routes", :yellow
        else
          route route_line
        end
      end

      def create_initializer
        template "swarmpod.rb.tt", "config/initializers/swarmpod.rb"
      end

      def create_cable_config
        if File.exist?(Rails.root.join("config", "cable.yml"))
          say_status :skip, "config/cable.yml already exists", :yellow
        else
          template "cable.yml.tt", "config/cable.yml"
        end
      end

      def create_swarmpodfile
        template "Swarmpodfile.tt", "Swarmpodfile"
      end

      def create_prompts_directory
        template "sample_prompt.md.tt", "prompts/sample.md"
      end

      def create_tmp_directories
        %w[workspace output gems].each do |dir|
          path = "tmp/swarmpod/#{dir}"
          empty_directory path
          create_file "#{path}/.keep", ""
        end
      end

      def add_action_cable_meta_tag
        layout_path = Rails.root.join("app", "views", "layouts", "application.html.erb")
        return unless File.exist?(layout_path)

        layout = File.read(layout_path)
        return if layout.include?("action_cable_meta_tag")

        inject_into_file layout_path.to_s,
          "    <%= action_cable_meta_tag %>\n",
          after: "<%= csrf_meta_tags %>\n"
      end

      def add_gitignore_entries
        gitignore = Rails.root.join(".gitignore")
        return unless File.exist?(gitignore)

        entries = "\n# SwarmpodGem working directories\ntmp/swarmpod/\n"
        content = File.read(gitignore)
        return if content.include?("tmp/swarmpod/")

        append_to_file gitignore.to_s, entries
      end

      def print_post_install
        say ""
        say "SwarmpodGem installed successfully!", :green
        say ""
        say "  Engine mounted at: #{options[:mount_path]}"
        say "  Initializer:       config/initializers/swarmpod.rb"
        say "  Swarmpodfile:      Swarmpodfile"
        say "  Prompts:           prompts/"
        say "  Working dirs:      tmp/swarmpod/{workspace,output,gems}"
        say ""
        say "  Start your server and visit #{options[:mount_path]} to see the dashboard."
        say ""
      end

      private

      def routes_path
        Rails.root.join("config", "routes.rb")
      end

      def app_name
        Rails.application.class.module_parent_name.underscore
      end
    end
  end
end
