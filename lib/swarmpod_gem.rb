# frozen_string_literal: true

require "swarmpod_gem/version"
require "swarmpod_gem/configuration"
require "swarmpod_gem/engine" if defined?(Rails)

module SwarmpodGem
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def root
      @root ||= Pathname.new(File.expand_path("../..", __FILE__))
    end
  end
end
