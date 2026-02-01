# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "swarmpod_gem/version"

Gem::Specification.new do |spec|
  spec.name          = "swarmpod-gem"
  spec.version       = SwarmpodGem::VERSION
  spec.authors       = ["Eric Laquer"]
  spec.summary       = "SwarmPod multi-agent dashboard as a mountable Rails engine"
  spec.description   = "A Rails engine that provides a real-time multi-agent orchestration dashboard using ActionCable and Claude CLI."
  spec.homepage      = "https://github.com/laquereric/swarm-gem"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "app/**/*", "config/**/*", "prompts/**/*", "templates/**/*", "VERSION", "README.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "actioncable", ">= 7.0"
  spec.add_dependency "sprockets-rails"
end
