# frozen_string_literal: true

module SwarmpodGem
  class Engine < ::Rails::Engine
    isolate_namespace SwarmpodGem

    initializer "swarmpod_gem.assets" do |app|
      app.config.assets.paths << root.join("app", "assets", "javascripts")
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
      app.config.assets.precompile += %w[
        swarmpod_gem/application.js
        swarmpod_gem/application.css
      ]
    end

    initializer "swarmpod_gem.auto_boot", after: :load_config_initializers do
      if SwarmpodGem.configuration.auto_boot
        config.after_initialize do
          SwarmpodGem::Services::Orchestrator.boot!
        end
      end
    end

    initializer "swarmpod_gem.require_services" do
      require "swarmpod_gem/services/gemfile_parser"
      require "swarmpod_gem/services/state_manager"
      require "swarmpod_gem/services/ndjson_parser"
      require "swarmpod_gem/services/broadcast_debouncer"
      require "swarmpod_gem/services/clone_manager"
      require "swarmpod_gem/services/agent_spawner"
      require "swarmpod_gem/services/orchestrator"
    end
  end
end
