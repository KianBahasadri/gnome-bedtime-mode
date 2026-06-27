#!/usr/bin/env bash
# Remove the auto-grayscale daemon service and (optionally) the extension.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_DIR="$DIR/auto-grayscale"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
EXT_UUID="gnomebedtime@ionutbortis.gmail.com"

echo "==> Stopping auto-grayscale daemon..."
systemctl --user disable --now auto-grayscale.service 2>/dev/null || true
rm -f "$UNIT_DIR/auto-grayscale.service"
systemctl --user daemon-reload

echo "==> Turning off bedtime mode..."
"$DAEMON_DIR/auto-grayscale" off 2>/dev/null || true

read -rp "Also uninstall the gnome-bedtime-mode extension? [y/N] " answer
if [[ "${answer,,}" == "y" ]]; then
    gnome-extensions disable "$EXT_UUID" 2>/dev/null || true
    gnome-extensions uninstall "$EXT_UUID" 2>/dev/null \
        || rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$EXT_UUID"
    echo "Extension removed. Log out and back in to fully unload it."
else
    echo "Extension left installed (disabled only the daemon)."
fi

echo
echo "Uninstalled."
