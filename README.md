# dskup — Dev Setup Kickstarter

Launch your entire dev environment in iTerm2 with a single command. Define tabs, panes, splits, and commands in simple YAML configs.

```
dskup my-project
```

![iTerm2](https://img.shields.io/badge/iTerm2-required-blue) ![macOS](https://img.shields.io/badge/macOS-only-lightgrey) ![Python 3](https://img.shields.io/badge/python-3.7+-green)

## Features

- **YAML-driven configs** — one file per project, easy to read and share
- **Multi-tab layouts** — each tab can have multiple panes
- **Vertical & horizontal splits** — full control over pane arrangement
- **`split_from` targeting** — split any pane to build 2x2 grids and complex layouts
- **Per-pane working directories** — supports multi-repo setups
- **Directory inheritance** — `pane.dir` > `tab.dir` > `root`
- **New window per launch** — keeps your existing terminal untouched
- **Simple install** — one command, no global pip installs
- **Self-updating** — `dskup --upgrade` pulls the latest version

## Install

```bash
git clone https://github.com/sureshdsk/dskup.git ~/.dskup
~/.dskup/install.sh
```

Or via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/sureshdsk/dskup/main/install.sh | bash
```

### Prerequisites

1. **macOS** with [iTerm2](https://iterm2.com/downloads.html) installed
2. **Python 3.7+** (`brew install python3` if needed)
3. **Allow Automation**: On first run, macOS will ask to allow `osascript` to control iTerm2 — grant it once

## Usage

```bash
dskup my-project           # Launch a project dev environment
dskup --list               # List available project configs
dskup --edit my-project    # Create/edit a project config in $EDITOR
dskup --upgrade            # Update dskup to the latest version
dskup --version            # Show installed version
dskup --help               # Show help
```

## Create a New Project

```bash
# Option 1: Create from template and edit
dskup --edit my-project

# Option 2: Copy a sample config and customize
cp ~/.dskup/examples/django-celery.yaml ~/.config/dskup/configs/my-project.yaml
dskup --edit my-project

# Option 3: Create from scratch
cat > ~/.config/dskup/configs/my-project.yaml << 'EOF'
project: my-project
root: ~/Projects/my-project

tabs:
  - name: dev
    panes:
      - commands:
          - echo "hello from pane 1"
      - split: vertical
        split_from: 1
        commands:
          - echo "hello from pane 2"
EOF

# Launch it
dskup my-project
```

## Configuration

Configs live in `~/.config/dskup/configs/`. Each project gets a `.yaml` file.

### Example: Django + Celery + Frontend (multi-repo)

```yaml
project: my-django-app
root: ~/Developer

tabs:
  - name: backend
    dir: ~/Developer/backend-repo
    panes:
      - commands:
          - source venv/bin/activate
          - python manage.py runserver
      - split: vertical
        split_from: 1
        commands:
          - source venv/bin/activate
          - celery -A myapp worker --loglevel=info

  - name: frontend
    dir: ~/Developer/frontend-repo
    panes:
      - commands:
          - npm run dev
      - split: horizontal
        split_from: 1
        commands:
          - npm run build -- --watch

  - name: shell
    panes:
      - dir: ~/Developer/backend-repo
        commands:
          - git status
      - split: vertical
        split_from: 1
        dir: ~/Developer/frontend-repo
        commands:
          - git status
```

### Config Reference

| Key | Level | Description |
|-----|-------|-------------|
| `project` | top | Project name (for display) |
| `root` | top | Default working directory for all panes |
| `tabs` | top | List of tab definitions |
| `tabs[].name` | tab | Tab title shown in iTerm2 |
| `tabs[].dir` | tab | Default working directory for panes in this tab |
| `tabs[].panes` | tab | List of pane definitions |
| `panes[].dir` | pane | Working directory for this pane (overrides tab & root) |
| `panes[].commands` | pane | List of shell commands to run in order |
| `panes[].split` | pane | `"vertical"` or `"horizontal"` — split direction |
| `panes[].split_from` | pane | Which pane to split from (1-based, default: 1) |

**Directory resolution:** `pane.dir` → `tab.dir` → `root` → `~`

> The first pane in each tab is the base pane (no `split` needed). Subsequent panes specify their split direction and which pane to split from.

### More Examples

#### 2x2 Grid (4 panes)

```
┌──────────┬──────────┐
│  Pane 1  │  Pane 2  │
├──────────┼──────────┤
│  Pane 3  │  Pane 4  │
└──────────┴──────────┘
```

```yaml
project: my-app
root: ~/Developer/my-app

tabs:
  - name: dev
    panes:
      - commands:
          - make run-api
      - split: vertical
        split_from: 1
        commands:
          - make run-worker
      - split: horizontal
        split_from: 1
        commands:
          - make run-frontend
      - split: horizontal
        split_from: 2
        commands:
          - make run-tests
```

#### Just a shell

```yaml
project: scratch
root: ~/Developer

tabs:
  - name: work
    panes:
      - commands: []
```

## Sample Configs

The `examples/` folder includes ready-to-use configs for common stacks. Copy any to your config directory and customize:

```bash
cp ~/.dskup/examples/django-celery.yaml ~/.config/dskup/configs/my-project.yaml
dskup --edit my-project
```

| File | Stack | Layout |
|------|-------|--------|
| `django-celery.yaml` | Django + Celery + Redis | 2 tabs, 2 panes each |
| `python-fastapi.yaml` | FastAPI + Celery + pytest | 1 tab, 2x2 grid |
| `nextjs-fullstack.yaml` | Next.js + Prisma + Tailwind | 1 tab, 2x2 grid |
| `react-express.yaml` | React + Express (multi-repo) | 2 tabs, 2 panes each |
| `rails-sidekiq.yaml` | Rails + Sidekiq | 2 tabs, 2 panes each |
| `go-microservice.yaml` | Go + Air + Docker | 1 tab, 2x2 grid |
| `docker-compose.yaml` | Docker Compose stack | 1 tab, 3 panes |
| `flutter.yaml` | Flutter + tests + logs | 1 tab, 3 panes |

## File Locations

| What | Path |
|------|------|
| Install directory | `~/.dskup/` |
| User configs | `~/.config/dskup/configs/*.yaml` |
| CLI symlink | `~/.local/bin/dskup` |
| Virtualenv | `~/.dskup/.venv/` |

## Uninstall

```bash
~/.dskup/uninstall.sh
```

This will remove the CLI symlink and virtualenv, and optionally the install and config directories.

## How It Works

1. `dskup` (shell script) finds the YAML config and invokes `launcher.py`
2. `launcher.py` reads the YAML and generates AppleScript
3. The AppleScript is executed via `osascript` to:
   - Create a new iTerm2 window
   - Add tabs with named titles
   - Split panes vertically or horizontally (with `split_from` targeting)
   - `cd` to the configured directory in each pane
   - Run the specified commands

## Troubleshooting

**"Permission dialog on launch"** — macOS will ask to allow `osascript` to control iTerm2. Grant it once and it won't ask again.

**"dskup: command not found"** — Add `~/.local/bin` to your PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## License

MIT
