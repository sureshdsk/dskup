#!/usr/bin/env bash
#
# dskup uninstaller
# Removes the dskup CLI symlink, virtualenv, and optionally the install directory.
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

DSKUP_HOME="$HOME/.dskup"
CONFIG_DIR="$HOME/.config/dskup"
BIN_DIR="$HOME/.local/bin"
SYMLINK="$BIN_DIR/dskup"

info()  { echo -e "${CYAN}[dskup]${NC} $*"; }
ok()    { echo -e "${GREEN}[dskup]${NC} $*"; }
warn()  { echo -e "${YELLOW}[dskup]${NC} $*"; }

echo -e "${BOLD}dskup uninstaller${NC}"
echo ""

# Remove symlink
if [ -L "$SYMLINK" ] || [ -f "$SYMLINK" ]; then
    rm -f "$SYMLINK"
    ok "Removed symlink: $SYMLINK"
else
    info "No symlink found at $SYMLINK"
fi

# Remove virtualenv
if [ -d "$DSKUP_HOME/.venv" ]; then
    rm -rf "$DSKUP_HOME/.venv"
    ok "Removed virtualenv: $DSKUP_HOME/.venv"
fi

# Ask about install directory
if [ -d "$DSKUP_HOME" ]; then
    echo ""
    read -p "Remove install directory $DSKUP_HOME? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DSKUP_HOME"
        ok "Removed: $DSKUP_HOME"
    else
        info "Kept: $DSKUP_HOME"
    fi
fi

# Ask about config directory
if [ -d "$CONFIG_DIR" ]; then
    echo ""
    read -p "Remove config directory $CONFIG_DIR? (contains your project configs) [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        ok "Removed: $CONFIG_DIR"
    else
        info "Kept: $CONFIG_DIR (your configs are safe)"
    fi
fi

echo ""
echo -e "${GREEN}✓ dskup uninstalled.${NC}"
