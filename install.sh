#!/usr/bin/env bash
#
# dskup installer
# Works both via curl-pipe and locally after clone.
#
# curl -fsSL https://raw.githubusercontent.com/sureshdsk/dskup/main/install.sh | bash
# — or —
# git clone https://github.com/sureshdsk/dskup.git ~/.dskup && ~/.dskup/install.sh
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

DSKUP_HOME="$HOME/.dskup"
CONFIG_DIR="$HOME/.config/dskup/configs"
BIN_DIR="$HOME/.local/bin"
REPO_URL="https://github.com/sureshdsk/dskup.git"

info()  { echo -e "${CYAN}[dskup]${NC} $*"; }
ok()    { echo -e "${GREEN}[dskup]${NC} $*"; }
warn()  { echo -e "${YELLOW}[dskup]${NC} $*"; }
err()   { echo -e "${RED}[dskup]${NC} $*"; }

# --- Pre-flight checks ---

info "Checking prerequisites..."

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    err "dskup is designed for macOS with iTerm2. Detected: $(uname)"
    exit 1
fi

# Check iTerm2
if [ ! -d "/Applications/iTerm.app" ]; then
    err "iTerm2 not found at /Applications/iTerm.app"
    echo "  Install it from: https://iterm2.com/downloads.html"
    exit 1
fi
ok "iTerm2 found."

# Check Python 3
if ! command -v python3 &>/dev/null; then
    err "Python 3 not found. Install it via:"
    echo "  brew install python3"
    exit 1
fi
PYTHON3=$(command -v python3)
ok "Python 3 found: $PYTHON3"

# --- Clone or detect local install ---

# Determine if we're running from within the repo or via curl-pipe
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}" 2>/dev/null || echo ".")" && pwd)"

if [ -f "$SCRIPT_DIR/launcher.py" ] && [ -f "$SCRIPT_DIR/dskup" ]; then
    # Running locally from cloned repo
    SOURCE_DIR="$SCRIPT_DIR"
    info "Detected local install from: $SOURCE_DIR"
else
    # Running via curl-pipe — need to clone
    info "Cloning dskup to $DSKUP_HOME..."
    if [ -d "$DSKUP_HOME" ]; then
        warn "$DSKUP_HOME already exists. Pulling latest..."
        git -C "$DSKUP_HOME" pull --quiet
    else
        git clone --quiet "$REPO_URL" "$DSKUP_HOME"
    fi
    SOURCE_DIR="$DSKUP_HOME"
fi

# --- Install to DSKUP_HOME ---

if [ "$SOURCE_DIR" != "$DSKUP_HOME" ]; then
    info "Copying files to $DSKUP_HOME..."
    mkdir -p "$DSKUP_HOME"
    # Copy all project files (not .git if present)
    rsync -a --exclude='.git' --exclude='.venv' "$SOURCE_DIR/" "$DSKUP_HOME/"
fi

# --- Create virtualenv and install deps ---

VENV_DIR="$DSKUP_HOME/.venv"

if [ -d "$VENV_DIR" ]; then
    info "Virtualenv already exists. Updating dependencies..."
else
    info "Creating virtualenv at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
fi

info "Installing Python dependencies..."
"$VENV_DIR/bin/pip3" install --quiet --upgrade pip
"$VENV_DIR/bin/pip3" install --quiet -r "$DSKUP_HOME/requirements.txt"
ok "Dependencies installed."

# --- Symlink CLI ---

mkdir -p "$BIN_DIR"
SYMLINK="$BIN_DIR/dskup"

if [ -L "$SYMLINK" ] || [ -f "$SYMLINK" ]; then
    info "Updating existing symlink at $SYMLINK"
    rm -f "$SYMLINK"
fi

chmod +x "$DSKUP_HOME/dskup"
ln -s "$DSKUP_HOME/dskup" "$SYMLINK"
ok "Symlinked dskup → $SYMLINK"

# Check if BIN_DIR is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    warn "$BIN_DIR is not in your PATH."
    echo ""
    echo "  Add this to your ~/.zshrc (or ~/.bashrc):"
    echo ""
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# --- Set up user config directory ---

mkdir -p "$CONFIG_DIR"

if [ -z "$(ls -A "$CONFIG_DIR"/*.yaml 2>/dev/null)" ]; then
    info "Copying example config to $CONFIG_DIR/"
    cp "$DSKUP_HOME/examples/django-celery.yaml" "$CONFIG_DIR/example.yaml"
    ok "Example config created at $CONFIG_DIR/example.yaml"
else
    info "Existing configs found in $CONFIG_DIR/ — skipping example copy."
fi

# --- Done ---

echo ""
echo -e "${BOLD}${GREEN}✓ dskup installed successfully!${NC}"
echo ""
echo -e "${BOLD}Quick start:${NC}"
echo "  dskup --list               List available configs"
echo "  dskup --edit my-project    Create/edit a project config"
echo "  dskup my-project           Launch a dev environment"
echo ""
echo -e "${BOLD}Config directory:${NC} $CONFIG_DIR"
echo -e "${BOLD}Install directory:${NC} $DSKUP_HOME"
echo ""
echo -e "${YELLOW}Note:${NC} On first run, macOS may ask to allow osascript to control iTerm2."
echo "   Grant permission once and it won't ask again."
echo ""
