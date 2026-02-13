#!/usr/bin/env python3
"""
dskup launcher — reads a YAML config and generates AppleScript to
create a new iTerm2 window with tabs, panes, and commands.

Works from any terminal — no iTerm2 Python API connection needed.

Usage:
    python3 launcher.py <config_path>
"""

import sys
import os
import subprocess
import yaml


def load_config(config_path):
    """Load and validate a YAML config file."""
    config_path = os.path.expanduser(config_path)
    if not os.path.isfile(config_path):
        print(f"Error: Config file not found: {config_path}")
        sys.exit(1)

    with open(config_path, "r") as f:
        config = yaml.safe_load(f)

    if not config or "tabs" not in config:
        print("Error: Config must contain a 'tabs' key with at least one tab.")
        sys.exit(1)

    return config


def resolve_dir(pane, tab, root):
    """Resolve working directory: pane.dir > tab.dir > root."""
    d = pane.get("dir") or tab.get("dir") or root or "~"
    return os.path.expanduser(d)


def escape_applescript(s):
    """Escape a string for use inside AppleScript double quotes."""
    return s.replace("\\", "\\\\").replace('"', '\\"')


def build_pane_commands(pane_config, tab_config, root):
    """Build the shell commands string for a pane (cd + user commands)."""
    working_dir = resolve_dir(pane_config, tab_config, root)
    commands = [f"cd {working_dir}"]
    commands.extend(pane_config.get("commands", []))
    return commands


def generate_applescript(config):
    """Generate AppleScript to set up the iTerm2 layout.

    Strategy: store each session in an AppleScript variable (paneN_M),
    then split from specific variables and send commands to each.

    Each pane can specify:
      - split: "vertical" or "horizontal"
      - split_from: 1-based index of the pane to split from (default: 1)

    Example 2x2 grid:
      Pane 1: base (no split)
      Pane 2: split vertical from pane 1
      Pane 3: split horizontal from pane 1
      Pane 4: split horizontal from pane 2
    """
    root = config.get("root", "~")
    tabs_config = config["tabs"]

    lines = []
    lines.append('tell application "iTerm2"')
    lines.append("    activate")
    lines.append("    ")
    lines.append("    -- Create a new window")
    lines.append("    create window with default profile")
    lines.append("    ")
    lines.append("    tell current window")

    for tab_idx, tab_config in enumerate(tabs_config):
        tab_name = tab_config.get("name", "")
        panes_config = tab_config.get("panes", [])

        if not panes_config:
            continue

        if tab_idx == 0:
            lines.append("        ")
            lines.append("        -- First tab (already created with window)")
        else:
            lines.append("        ")
            lines.append(f"        -- Create tab: {tab_name}")
            lines.append("        create tab with default profile")

        # Variable prefix for this tab's panes
        prefix = f"t{tab_idx}"

        # Capture the base session (pane 1)
        lines.append(f"        set {prefix}_p1 to (current session)")

        # Create all splits, capturing each new session from the split return value
        for pane_idx, pane_config in enumerate(panes_config[1:], start=2):
            split_dir = pane_config.get("split", "vertical")
            split_from = pane_config.get("split_from", 1)
            source_var = f"{prefix}_p{split_from}"
            new_var = f"{prefix}_p{pane_idx}"

            lines.append(f"        ")
            lines.append(f"        -- Split pane {split_from} {split_dir}ly to create pane {pane_idx}")
            lines.append(f"        tell {source_var}")
            if split_dir == "horizontal":
                lines.append(f"            set {new_var} to (split horizontally with default profile)")
            else:
                lines.append(f"            set {new_var} to (split vertically with default profile)")
            lines.append(f"        end tell")

        # Now send commands to each pane
        lines.append(f"        ")
        lines.append(f"        -- Send commands to each pane")
        for pane_idx, pane_config in enumerate(panes_config, start=1):
            pane_cmds = build_pane_commands(pane_config, tab_config, root)
            var_name = f"{prefix}_p{pane_idx}"

            lines.append(f"        tell {var_name}")
            # Set tab name on pane 1
            if pane_idx == 1 and tab_name:
                escaped_name = escape_applescript(tab_name)
                lines.append(f'            write text "printf \\"\\\\e]1;{escaped_name}\\\\a\\""')
            for cmd in pane_cmds:
                escaped_cmd = escape_applescript(cmd)
                lines.append(f'            write text "{escaped_cmd}"')
            lines.append(f"        end tell")

    # Select the first tab
    if len(tabs_config) > 1:
        lines.append("        ")
        lines.append("        select first tab")

    lines.append("    end tell")
    lines.append("end tell")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: launcher.py <config_path>")
        sys.exit(1)

    config_path = sys.argv[1]
    config = load_config(config_path)

    script = generate_applescript(config)

    # Debug: print script if DSKUP_DEBUG is set
    if os.environ.get("DSKUP_DEBUG"):
        print("--- Generated AppleScript ---")
        print(script)
        print("--- End ---")

    # Execute via osascript
    result = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print(f"Error running AppleScript: {result.stderr.strip()}")
        sys.exit(1)


if __name__ == "__main__":
    main()
