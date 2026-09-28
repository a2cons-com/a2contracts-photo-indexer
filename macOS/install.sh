#!/bin/sh
# macOS/install.sh interval|daemon [SECONDS] -- installs (or replaces) the launchd agent.
#   interval: `run --once` every 30 minutes while the Mac is awake
#   daemon:   `run` always on, models stay loaded (~16 GB); checks for new
#             work every SECONDS when idle (default 20)
# macOS/install.sh remove -- stops and removes it.
set -e
MODE=${1:?usage: $0 interval|daemon [SECONDS]|remove}
INTERVAL=${2:-20}
case "$INTERVAL" in ''|*[!0-9]*) echo "SECONDS must be a whole number: $INTERVAL" >&2; exit 1;; esac
REPO=$(cd "$(dirname "$0")/.." && pwd)
LABEL=com.a2cons.photo-indexer
DEST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
if [ "$MODE" = remove ]; then
    rm -f "$DEST"
    echo "removed $LABEL"
    exit 0
fi
[ -f "$REPO/macOS/$LABEL.$MODE.plist" ] || { echo "unknown mode: $MODE" >&2; exit 1; }
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
sed -e "s|REPO/|$REPO/|" -e "s|HOME/|$HOME/|g" -e "s|<string>INTERVAL</string>|<string>$INTERVAL</string>|" "$REPO/macOS/$LABEL.$MODE.plist" > "$DEST"
plutil -lint "$DEST" >/dev/null
launchctl bootstrap "$DOMAIN" "$DEST"
if [ "$MODE" = daemon ]; then WHAT="daemon, idle check every ${INTERVAL}s"; else WHAT=$MODE; fi
echo "installed $LABEL ($WHAT); log: tail -f ~/Library/Logs/a2-photo-indexer.log"
