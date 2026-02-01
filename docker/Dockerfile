FROM ruby:3.2-slim

# Install git (for lazy gem cloning), Node.js (for Claude CLI), and build essentials
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git ca-certificates curl build-essential && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g @anthropic-ai/claude-code && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Ruby dependencies
COPY Gemfile swarmpod-gem.gemspec VERSION ./
COPY lib/swarmpod_gem/version.rb lib/swarmpod_gem/version.rb
RUN bundle install --jobs 4

# Copy application code
COPY . .

RUN mkdir -p /output /gems

EXPOSE 4000

ENV SWARMPOD_GEMFILE=/app/Gemfile \
    SWARMPOD_PROMPTS=/app/prompts

CMD ["bundle", "exec", "rackup", "-p", "4000", "-o", "0.0.0.0"]
