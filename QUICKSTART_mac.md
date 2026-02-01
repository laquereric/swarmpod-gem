# SwarmPod-Gem: Mac Quickstart

![SwarmPod Dashboard](SwarmPod.png)

Go from a fresh Mac to a running multi-agent orchestration dashboard.

There are two paths: **Docker** (recommended, fewer prerequisites) or **Local** (for development).

---

## Path A: Docker (Recommended)

### 1. Install Xcode Command Line Tools

Open Terminal (Applications > Utilities > Terminal) and run:

```bash
xcode-select --install
```

Click "Install" in the dialog that appears. This provides `git` and essential build tools.

### 2. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the instructions printed at the end to add Homebrew to your PATH. For Apple Silicon Macs, this is typically:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Verify:

```bash
brew --version
```

### 3. Install Docker Desktop

```bash
brew install --cask docker
```

Open Docker Desktop from Applications and complete the setup wizard. Wait until the Docker icon in the menu bar shows "Docker Desktop is running."

Verify:

```bash
docker --version
docker compose version
```

### 4. Clone the Repository

```bash
cd ~/Documents/GitHub   # or wherever you keep projects
git clone https://github.com/laquereric/swarmpod-gem.git
cd swarmpod-gem
```

### 5. Configure Your Anthropic API Key

Copy the example secrets file and add your key:

```bash
cp secrets_example/ANTHROPIC_API_KEY.sh secrets/ANTHROPIC_API_KEY.sh
```

Edit `secrets/ANTHROPIC_API_KEY.sh` and replace the placeholder with your actual key:

```bash
export ANTHROPIC_API_KEY=sk-ant-xxxxx-your-key-here
```

Get a key at [console.anthropic.com](https://console.anthropic.com/) if you don't have one.

Then load it into your shell:

```bash
source secrets/ANTHROPIC_API_KEY.sh
```

### 6. Start SwarmPod

```bash
bin/up
```

This builds the Docker image (Ruby 3.2, Node.js 22, Claude CLI, all gem dependencies) and starts the application.

### 7. Open the Dashboard

Browse to: **http://localhost:4000**

### 8. Stop SwarmPod

```bash
bin/down
```

---

## Path B: Local Development

Use this path if you want to run SwarmPod directly on your Mac without Docker.

### 1. Install Xcode Command Line Tools

```bash
xcode-select --install
```

### 2. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Add to PATH (Apple Silicon):

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 3. Install Ruby via rbenv

```bash
brew install rbenv ruby-build
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

rbenv install 3.2.6
rbenv global 3.2.6
```

Verify:

```bash
ruby --version    # should show 3.2.x
gem --version
```

### 4. Install Node.js 22

```bash
brew install node@22
```

If `node` isn't on your PATH after install, link it:

```bash
brew link --overwrite node@22
```

Verify:

```bash
node --version    # should show v22.x
npm --version
```

### 5. Install Claude CLI

```bash
npm install -g @anthropic-ai/claude-code
```

Verify:

```bash
claude --version
```

### 6. Install Bundler

```bash
gem install bundler
```

### 7. Clone the Repository

```bash
cd ~/Documents/GitHub
git clone https://github.com/laquereric/swarmpod-gem.git
cd swarmpod-gem
```

### 8. Install Ruby Dependencies

```bash
bundle install
```

### 9. Configure Your Anthropic API Key

```bash
cp secrets_example/ANTHROPIC_API_KEY.sh secrets/ANTHROPIC_API_KEY.sh
```

Edit `secrets/ANTHROPIC_API_KEY.sh` with your key, then load it:

```bash
source secrets/ANTHROPIC_API_KEY.sh
```

### 10. Create Working Directories

```bash
mkdir -p /tmp/swarmpod-output /tmp/swarmpod-gems
```

### 11. Start the Server

```bash
export WORKSPACE="$(pwd)"
export OUTPUT=/tmp/swarmpod-output
export GEMS_DIR=/tmp/swarmpod-gems
export SWARMPOD_GEMFILE="$(pwd)/Gemfile"
export SWARMPOD_PROMPTS="$(pwd)/prompts"

bundle exec rackup -p 4000 -o 0.0.0.0
```

### 12. Open the Dashboard

Browse to: **http://localhost:4000**

---

## Verify Everything Works

Once the dashboard loads, you should see:

- Agent tabs organized by Gemfile groups (**web**, **experts**, **foci**)
- Real-time status updates via WebSocket
- Ability to send messages that get routed to Claude-powered agents

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `docker: command not found` | Open Docker Desktop app and wait for it to fully start |
| `bin/up` permission denied | Run `chmod +x bin/up bin/down` |
| Port 4000 already in use | Stop the other process or set `PORT=4001` before running |
| `ANTHROPIC_API_KEY` not set | Run `source secrets/ANTHROPIC_API_KEY.sh` in your terminal |
| Bundle install fails on native extensions | Ensure Xcode CLT is installed: `xcode-select --install` |
| `rbenv: command not found` after install | Restart your terminal or run `source ~/.zshrc` |
| Docker build hangs on Apple Silicon | Ensure Docker Desktop has Rosetta emulation enabled in Settings > General |

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | (required) | Your Anthropic API key |
| `WORKSPACE` | `/workspace` | Project directory mounted into container |
| `OUTPUT` | `/output` | Agent output directory |
| `GEMS_DIR` | `/gems` | Cached gems directory |
| `PORT` | `4000` | Application port |
| `SWARMPOD_GEMFILE` | - | Path to Gemfile defining agent groups |
| `SWARMPOD_PROMPTS` | - | Path to prompts directory |
| `SWARMPOD_AUTO_BOOT` | `true` | Auto-start orchestrator on launch |
| `RAILS_ENV` | `production` | Rails environment |
| `LOG_LEVEL` | `info` | Logging verbosity (`debug`, `info`, `warn`, `error`) |
