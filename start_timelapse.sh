#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=TimelapseFunctions.sh
source "$PROJECT_DIR/TimelapseFunctions.sh"

read_timelapse_config
prepare_workspace
acquire_capture_lock
validate_runtime
initialize_timelapse
log "Capture started: location=$LOCATION interval=${INTERVAL}s light=${LIGHT_LOWER}-${LIGHT_UPPER}."

counter=$(read_persisted_count "$COUNT_FILE" working_average_image.tif)
movement_counter=0
if [[ "$MOVEMENT" == true ]]; then
  movement_counter=$(read_persisted_count "$MOVEMENT_COUNT_FILE" working_movement_average.tif)
fi
trap 'cleanup_temporary_files' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

while sanity_check "$counter"; do
  started_at=$(date +%s)
  capture_images
  make_hdr_image

  if check_light_levels; then
    ((counter += 1))
    make_average_image current_hdr_image.tif working_average_image.tif "$counter"
    persist_count "$COUNT_FILE" "$counter"
    if [[ "$MOVEMENT" == true ]]; then
      ((movement_counter += 1))
      make_movement_image
      make_average_image current_movement_image.png working_movement_average.tif "$movement_counter"
      persist_count "$MOVEMENT_COUNT_FILE" "$movement_counter"
    fi
    printf 'Accepted image count: %s\n' "$counter" >>"$STATUS_FILE"
  else
    log "Frame rejected by light-level limits."
  fi

  cleanup_temporary_files
  sleep_until_next_capture "$started_at"
done
