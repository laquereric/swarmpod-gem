source "https://rubygems.org"

gemspec

gem "puma"
gem "rackup"

group :web do
  gem "presentation-gem", git: "https://github.com/laquereric/presentation-gem.git"
  gem "process-gem",      git: "https://github.com/laquereric/process-gem.git"
  gem "semantic-gem",     git: "https://github.com/laquereric/semantic-gem.git"
end

group :experts do
  gem "experts-gem", git: "https://github.com/laquereric/experts-gem.git"
end

group :foci do
  gem "foci-gem", git: "https://github.com/laquereric/foci-gem.git"
end

group :development, :test do
  gem "rspec-rails"
end
