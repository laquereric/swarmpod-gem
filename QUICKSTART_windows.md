# SwarmPod-Gem: Windows Quickstart

![SwarmPod Dashboard](SwarmPod.png)

Go from a fresh Windows machine to a running multi-agent orchestration dashboard.

SwarmPod uses bash scripts and Unix tooling, so all paths run through **WSL2** (Windows Subsystem for Linux). There are two paths: **Docker** (recommended, fewer prerequisites) or **Local** (for development).

---

## Prerequisites: Enable WSL2

### 1. Install WSL2 with Ubuntu

Open **PowerShell as Administrator** (right-click Start > Terminal (Admin)) and run:

```powershell
wsl --install
```

This installs WSL2 with Ubuntu by default. **Restart your computer** when prompted.

After reboot, Ubuntu will open automatically and ask you to create a username and password.

Verify from PowerShell:

```powershell
wsl --version
wsl -l -v
```

### 2. Open Your WSL Terminal

All remaining commands run **inside WSL**. You can open it by:

- Typing `ubuntu` in the Start menu
- Running `wsl` from PowerShell
- Opening the "Ubuntu" profile in Windows Terminal

---

## Path A: Docker (Recommended)

### 1. Install Docker Desktop for Windows

Download and install from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/).

During setup, ensure **"Use WSL 2 based engine"** is checked.

After installation, open Docker Desktop and go to **Settings > Resources > WSL Integration**. Enable integration for your Ubuntu distribution.

Verify inside WSL:

```bash
docker --version
docker compose version
```

### 2. Install Git (inside WSL)

```bash
sudo apt update
sudo apt install -y git
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
nano secrets/ANTHROPIC_API_KEY.sh
```

Set the content to:

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
chmod +x bin/up bin/down
bin/up
```

This builds the Docker image (Ruby 3.2, Node.js 22, Claude CLI, all gem dependencies) and starts the application.

### 6. Open the Dashboard

Open a browser **on Windows** and go to: **http://localhost:4000**

(Docker Desktop forwards ports from WSL to Windows automatically.)

### 7. Stop SwarmPod

```bash
bin/down
```

---

## Path B: Local Development (inside WSL)

Use this path if you want to run SwarmPod directly in WSL without Docker.

### 1. Install System Dependencies

Inside your WSL Ubuntu terminal:

```bash
sudo apt update
sudo apt install -y git curl build-essential libssl-dev libreadline-dev zlib1g-dev libyaml-dev libffi-dev
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
nano secrets/ANTHROPIC_API_KEY.sh
```

Set the content to your key, then load it:

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

Open a browser **on Windows** and go to: **http://localhost:4000**

(WSL2 automatically forwards ports to the Windows host.)

---

## Verify Everything Works

Once the dashboard loads, you should see:

- Agent tabs organized by Gemfile groups (**web**, **experts**, **foci**)
- Real-time status updates via WebSocket
- Ability to send messages that get routed to Claude-powered agents

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `wsl --install` fails | Enable "Virtual Machine Platform" in Windows Features (Control Panel > Programs > Turn Windows features on or off) |
| Docker not available inside WSL | Open Docker Desktop > Settings > Resources > WSL Integration and enable your distro |
| `localhost:4000` not reachable from Windows | Try `127.0.0.1:4000` instead, or run `wsl hostname -I` to get the WSL IP |
| `bin/up` permission denied | Run `chmod +x bin/up bin/down` inside WSL |
| Port 4000 already in use | Stop the other process or set `PORT=4001` before running |
| `ANTHROPIC_API_KEY` not set | Run `source secrets/ANTHROPIC_API_KEY.sh` in your WSL terminal |
| Line ending issues (`\r` errors in scripts) | Run `sudo apt install dos2unix && dos2unix bin/up bin/down` |
| Bundle install fails with missing headers | Install dev libraries: `sudo apt install libssl-dev libreadline-dev zlib1g-dev` |
| WSL is very slow on file access | Clone the repo inside WSL's filesystem (`~/projects/`), not under `/mnt/c/` |
| Docker build fails with memory errors | Increase WSL memory: create `%USERPROFILE%\.wslconfig` with `[wsl2]` and `memory=8GB` |

## Important: File System Performance

Always keep your project files **inside the WSL filesystem** (e.g., `~/projects/swarmpod-gem`), not on the Windows mount (`/mnt/c/...`). Accessing files across the boundary is significantly slower and can cause issues with file watchers and git.

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
