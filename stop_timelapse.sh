#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=TimelapseFunctions.sh
source "$PROJECT_DIR/TimelapseFunctions.sh"

read_timelapse_config
prepare_workspace
touch "$PAUSE_FILE"
log "Stop requested; capture will stop after the current processing step."

if [[ "$HDMI" == true ]] && command -v tvservice >/dev/null 2>&1; then
  tvservice -p || true
fi
