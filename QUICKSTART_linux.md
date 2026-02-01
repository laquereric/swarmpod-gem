# SwarmPod-Gem: Linux Quickstart

![SwarmPod Dashboard](SwarmPod.png)

Go from a fresh Linux install to a running multi-agent orchestration dashboard.

There are two paths: **Docker** (recommended, fewer prerequisites) or **Local** (for development).

Instructions use **Ubuntu/Debian** commands. Fedora/RHEL equivalents are noted where they differ.

---

## Path A: Docker (Recommended)

### 1. Install System Prerequisites

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install -y git curl
```

**Fedora/RHEL:**

```bash
sudo dnf install -y git curl
```

### 2. Install Docker Engine

```bash
# Add Docker's official GPG key and repository (Ubuntu/Debian)
sudo apt install -y ca-certificates gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

**Fedora/RHEL:**

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

Enable and start Docker, then add your user to the `docker` group so you can run without `sudo`:

```bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

**Log out and log back in** for the group change to take effect.

Verify:

```bash
docker --version
docker compose version
```

### 3. Clone the Repository

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/laquereric/swarmpod-gem.git
cd swarmpod-gem
```

### 4. Configure Your Anthropic API Key

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

### 5. Start SwarmPod

```bash
bin/up
```

If you get a permission error:

```bash
chmod +x bin/up bin/down
bin/up
```

This builds the Docker image (Ruby 3.2, Node.js 22, Claude CLI, all gem dependencies) and starts the application.

### 6. Open the Dashboard

Browse to: **http://localhost:4000**

### 7. Stop SwarmPod

```bash
bin/down
```

---

## Path B: Local Development

Use this path if you want to run SwarmPod directly on your machine without Docker.

### 1. Install System Dependencies

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install -y git curl build-essential libssl-dev libreadline-dev zlib1g-dev libyaml-dev libffi-dev
```

**Fedora/RHEL:**

```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y git curl openssl-devel readline-devel zlib-devel libyaml-devel libffi-devel
```

### 2. Install Ruby via rbenv

```bash
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
```

Add rbenv to your shell:

```bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
source ~/.bashrc
```

Install Ruby 3.2:

```bash
rbenv install 3.2.6
rbenv global 3.2.6
```

Verify:

```bash
ruby --version    # should show 3.2.x
gem --version
```

### 3. Install Node.js 22

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

**Fedora/RHEL:**

```bash
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo dnf install -y nodejs
```

Verify:

```bash
node --version    # should show v22.x
npm --version
```

### 4. Install Claude CLI

```bash
npm install -g @anthropic-ai/claude-code
```

If you get a permissions error:

```bash
sudo npm install -g @anthropic-ai/claude-code
```

Verify:

```bash
claude --version
```

### 5. Install Bundler

```bash
gem install bundler
```

### 6. Clone the Repository

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/laquereric/swarmpod-gem.git
cd swarmpod-gem
```

### 7. Install Ruby Dependencies

```bash
bundle install
```

### 8. Configure Your Anthropic API Key

```bash
cp secrets_example/ANTHROPIC_API_KEY.sh secrets/ANTHROPIC_API_KEY.sh
```

Edit `secrets/ANTHROPIC_API_KEY.sh` with your key, then load it:

```bash
source secrets/ANTHROPIC_API_KEY.sh
```

### 9. Create Working Directories

```bash
mkdir -p /tmp/swarmpod-output /tmp/swarmpod-gems
```

### 10. Start the Server

```bash
export WORKSPACE="$(pwd)"
export OUTPUT=/tmp/swarmpod-output
export GEMS_DIR=/tmp/swarmpod-gems
export SWARMPOD_GEMFILE="$(pwd)/Gemfile"
export SWARMPOD_PROMPTS="$(pwd)/prompts"

bundle exec rackup -p 4000 -o 0.0.0.0
```

### 11. Open the Dashboard

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
| `permission denied` on Docker commands | Log out and back in after `usermod -aG docker $USER` |
| `bin/up` permission denied | Run `chmod +x bin/up bin/down` |
| Port 4000 already in use | Stop the other process or set `PORT=4001` before running |
| `ANTHROPIC_API_KEY` not set | Run `source secrets/ANTHROPIC_API_KEY.sh` in your terminal |
| Bundle install fails with missing headers | Install dev libraries: `sudo apt install libssl-dev libreadline-dev zlib1g-dev` |
| `rbenv: command not found` after install | Restart your terminal or run `source ~/.bashrc` |
| npm global install permission error | Use `sudo npm install -g` or configure npm prefix: `npm config set prefix ~/.npm-global` |
| Docker compose not found | Ensure you installed `docker-compose-plugin` (v2), not the legacy `docker-compose` (v1) |

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
