#!/usr/bin/env bash
# Install gnome-bedtime-mode extension + auto-grayscale daemon service.
# Safe to re-run.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_DIR="$DIR/auto-grayscale"
DAEMON="$DAEMON_DIR/auto-grayscale"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
EXT_UUID="gnomebedtime@ionutbortis.gmail.com"

echo "==> Building gnome-bedtime-mode extension..."
bash "$DIR/scripts/build.sh"

echo "==> Installing extension..."
ZIP_FILE="$(ls "$DIR/build"/gnome-bedtime-mode_*.zip 2>/dev/null | head -1)"
if [[ -z "$ZIP_FILE" ]]; then
    echo "error: no built zip found in $DIR/build/"
    exit 1
fi
gnome-extensions install --force "$ZIP_FILE"

echo "==> Enabling extension..."
gnome-extensions enable "$EXT_UUID" 2>/dev/null \
    || echo "    note: could not enable yet; it will be enabled after you log out and back in."

echo "==> Setting up auto-grayscale daemon..."
chmod +x "$DAEMON"
mkdir -p "$UNIT_DIR"

if [[ ! -f "$DAEMON_DIR/.env" && -f "$DAEMON_DIR/.env.example" ]]; then
    cp "$DAEMON_DIR/.env.example" "$DAEMON_DIR/.env"
fi

# Install the systemd unit, substituting the actual daemon path.
sed "s|@DAEMON_PATH@|$DAEMON|" "$DAEMON_DIR/auto-grayscale.service" \
    > "$UNIT_DIR/auto-grayscale.service"

systemctl --user daemon-reload
systemctl --user enable --now auto-grayscale.service

echo
echo "Installed."
echo "  - gnome-bedtime-mode extension: visual effect + preferences UI"
echo "  - auto-grayscale daemon:        toggles bedtime mode at sunset/sunrise"
echo
echo "IMPORTANT: log out and back in once so GNOME loads the extension."
echo "Until then the daemon runs but bedtime mode has no effect."
echo
systemctl --user --no-pager status auto-grayscale.service 2>/dev/null | head -6 || true
echo
"$DAEMON" status
