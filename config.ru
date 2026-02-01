# frozen_string_literal: true

# Minimal standalone Rack app for running swarmpod-gem in Docker
# without a full host Rails application.

require "rails"
require "action_controller/railtie"
require "action_cable/engine"
require "sprockets/railtie"

require_relative "lib/swarmpod_gem"

class SwarmpodStandaloneApp < Rails::Application
  config.load_defaults 7.0
  config.eager_load = true
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "swarmpod-dev-secret")
  config.hosts.clear

  # ActionCable async adapter (no Redis needed)
  config.action_cable.cable = { "adapter" => "async" }
  config.action_cable.mount_path = "/cable"

  # Asset pipeline
  config.assets.enabled = true
  config.assets.compile = true

  # Logging
  config.logger = Logger.new($stdout)
  config.log_level = ENV.fetch("LOG_LEVEL", "info").to_sym

  routes.draw do
    mount SwarmpodGem::Engine, at: "/"
  end
end

SwarmpodStandaloneApp.initialize!

run SwarmpodStandaloneApp
