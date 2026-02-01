# Rails Application Template for SwarmpodGem
#
# Usage:
#   rails new myapp -m path/to/swarmpod-gem/templates/rails_template.rb
#
# This template sets up a new Rails app with swarmpod-gem pre-configured.

# Add swarmpod-gem to the Gemfile
gem "swarmpod-gem", github: "laquereric/swarm-gem", glob: "swarmpod-gem/*.gemspec", require: "swarmpod_gem"

# Ensure puma is present (Rails 7+ includes it by default, but just in case)
gem "puma" unless IO.read("Gemfile").include?("puma")

after_bundle do
  # Run the install generator
  generate "swarmpod_gem:install"

  # Create an initial git commit with everything configured
  git add: "."
  git commit: '-m "Initial commit with SwarmpodGem configured"'
end
