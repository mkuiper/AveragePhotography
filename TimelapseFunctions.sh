#!/usr/bin/env bash

# Shared functions for the AveragePhotography entry-point scripts.
# This file is sourced; strict mode is enabled by each entry point.

PROJECT_DIR="${PROJECT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
CONFIG_FILE="${TIMELAPSE_CONFIG:-$PROJECT_DIR/Timelapse_Config.txt}"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

read_timelapse_config() {
  [[ -r "$CONFIG_FILE" ]] || die "Configuration file is not readable: $CONFIG_FILE"
  # shellcheck source=Timelapse_Config.txt
  source "$CONFIG_FILE"

  : "${LOCATION:?LOCATION must be set in $CONFIG_FILE}"
  : "${TOPDIR:?TOPDIR must be set in $CONFIG_FILE}"
  : "${INTERVAL:?INTERVAL must be set in $CONFIG_FILE}"
  : "${LIGHT_LOWER:?LIGHT_LOWER must be set in $CONFIG_FILE}"
  : "${LIGHT_UPPER:?LIGHT_UPPER must be set in $CONFIG_FILE}"
  : "${EXPOSURE_FLAG:?EXPOSURE_FLAG must be set in $CONFIG_FILE}"

  [[ "$INTERVAL" =~ ^[0-9]+$ ]] && ((INTERVAL > 0)) || die "INTERVAL must be a positive integer"
  [[ "$LIGHT_LOWER" =~ ^[0-9]+$ && "$LIGHT_UPPER" =~ ^[0-9]+$ ]] || die "Light limits must be integers"
  ((LIGHT_LOWER >= 0 && LIGHT_UPPER <= 255 && LIGHT_LOWER <= LIGHT_UPPER)) ||
    die "Light limits must satisfy 0 <= LIGHT_LOWER <= LIGHT_UPPER <= 255"
  [[ "$LOCATION" =~ ^[A-Za-z0-9._-]+$ ]] || die "LOCATION may only contain letters, numbers, dot, underscore, and dash"
  declare -p CAMERA_COMMAND >/dev/null 2>&1 || die "CAMERA_COMMAND must be a Bash array"
  declare -p EXPOSURES >/dev/null 2>&1 || die "EXPOSURES must be a Bash array"
  ((${#CAMERA_COMMAND[@]} > 0)) || die "CAMERA_COMMAND cannot be empty"
  ((${#EXPOSURES[@]} > 0)) || die "EXPOSURES cannot be empty"

  TOPDIR="${TOPDIR%/}"
  MAX_DAILY_IMAGES="${MAX_DAILY_IMAGES:-5000}"
  [[ "$MAX_DAILY_IMAGES" =~ ^[1-9][0-9]*$ ]] || die "MAX_DAILY_IMAGES must be a positive integer"
  ARCHIVE="${ARCHIVE:-$TOPDIR/FrameArchive}"
  ARCHIVE7="${ARCHIVE7:-$TOPDIR/FrameArchive7day}"
  ARCHIVE30="${ARCHIVE30:-$TOPDIR/FrameArchive30day}"
  ARCHIVEMOVEMENT="${ARCHIVEMOVEMENT:-$TOPDIR/FrameArchiveMovement}"
  LOG_FILE="${LOG_FILE:-$TOPDIR/log_file.txt}"
  STATUS_FILE="${STATUS_FILE:-$TOPDIR/last_message.txt}"
  PAUSE_FILE="${PAUSE_FILE:-$TOPDIR/pause_timelapse.txt}"
  COUNT_FILE="${COUNT_FILE:-$TOPDIR/.accepted_frame_count}"
  MOVEMENT_COUNT_FILE="${MOVEMENT_COUNT_FILE:-$TOPDIR/.movement_frame_count}"
  MOVEMENT="${MOVEMENT:-false}"
  HDMI="${HDMI:-false}"
  EMAIL="${EMAIL:-}"
  [[ "$MOVEMENT" == true || "$MOVEMENT" == false ]] || die "MOVEMENT must be true or false"
  [[ "$HDMI" == true || "$HDMI" == false ]] || die "HDMI must be true or false"
}

read_persisted_count() {
  local count_file=$1 average_file=$2 count=0
  if [[ -f "$count_file" ]]; then
    read -r count <"$count_file"
    [[ "$count" =~ ^[0-9]+$ ]] || die "Invalid frame count in $count_file"
  elif [[ -f "$average_file" ]]; then
    die "$average_file exists without $count_file; archive or remove the incomplete daily state"
  fi
  printf '%s\n' "$count"
}

persist_count() {
  local count_file=$1 count=$2 temporary="${count_file}.tmp"
  printf '%s\n' "$count" >"$temporary"
  mv -- "$temporary" "$count_file"
}

prepare_workspace() {
  mkdir -p "$TOPDIR" "$ARCHIVE" "$ARCHIVE7" "$ARCHIVE30"
  [[ "$MOVEMENT" == true ]] && mkdir -p "$ARCHIVEMOVEMENT"
  touch "$LOG_FILE"
  cd "$TOPDIR"
}

acquire_capture_lock() {
  require_command flock
  exec 9>"$TOPDIR/.capture.lock"
  flock -n 9 || die "Another capture or archive process is already running"
}

validate_runtime() {
  require_command "${CAMERA_COMMAND[0]}"
  require_command enfuse
  require_command convert
  require_command composite
  if [[ -n "$EMAIL" ]]; then
    require_command mpack
  fi
}

initialize_timelapse() {
  printf 'Starting timelapse.\n' >"$STATUS_FILE"
  rm -f -- "$PAUSE_FILE"
  if [[ "$HDMI" == true ]]; then
    require_command tvservice
    tvservice -o
    printf 'Turning off HDMI.\n' >>"$STATUS_FILE"
  fi
}

capture_images() {
  local exposure output index=0
  rm -f -- temp_image*.jpg
  for exposure in "${EXPOSURES[@]}"; do
    ((index += 1))
    output=$(printf 'temp_image%02d.jpg' "$index")
    "${CAMERA_COMMAND[@]}" "$EXPOSURE_FLAG" "$exposure" -o "$output"
    [[ -s "$output" ]] || die "Camera did not create $output"
  done
}

make_hdr_image() {
  local inputs=(temp_image*.jpg)
  ((${#inputs[@]} >= 1)) || die "No captured images found"
  enfuse --output current_hdr_image.tif "${inputs[@]}"
  [[ -s current_hdr_image.tif ]] || die "HDR processing did not create current_hdr_image.tif"

  local initial_image
  for initial_image in working_average_image.tif running_7day_average_image.tif \
    running_30day_average_image.tif yesterday_average.tif; do
    if [[ ! -f "$initial_image" ]]; then
      cp -- current_hdr_image.tif "$initial_image"
      printf 'Initialized %s\n' "$initial_image" >>"$STATUS_FILE"
    fi
  done
}

check_light_levels() {
  local pixel
  pixel=$(convert current_hdr_image.tif -colorspace gray -resize 1x1 -format '%[fx:round(255*mean)]' info:)
  [[ "$pixel" =~ ^[0-9]+$ ]] || die "Could not determine image light level (got: $pixel)"
  printf 'Light level: %s\n' "$pixel" >"$STATUS_FILE"
  ((pixel >= LIGHT_LOWER && pixel <= LIGHT_UPPER))
}

make_average_image() {
  local current_image=$1 average_image=$2 sample_count=$3
  local new_weight old_weight temporary
  [[ -f "$current_image" ]] || die "Current image not found: $current_image"
  [[ -f "$average_image" ]] || cp -- "$current_image" "$average_image"
  [[ "$sample_count" =~ ^[1-9][0-9]*$ ]] || die "Sample count must be a positive integer"

  new_weight=$(convert xc: -format "%[fx:100/$sample_count]" info:)
  old_weight=$(convert xc: -format "%[fx:100-(100/$sample_count)]" info:)
  temporary=$(mktemp --suffix=.tif "$TOPDIR/.average.XXXXXX")
  composite -blend "${old_weight}x${new_weight}" "$average_image" "$current_image" "$temporary"
  mv -- "$temporary" "$average_image"
  printf 'Blended %s: old=%s%% new=%s%%\n' "$average_image" "$old_weight" "$new_weight" >>"$STATUS_FILE"
}

make_movement_image() {
  composite current_hdr_image.tif yesterday_average.tif -compose difference current_movement_image.png
  convert current_movement_image.png -fuzz 10% -transparent black current_movement_image.png
}

sanity_check() {
  local counter=$1
  if [[ -f "$PAUSE_FILE" ]]; then
    log "Pause flag present; capture stopped."
    return 1
  fi
  if ((counter > MAX_DAILY_IMAGES)); then
    log "Safety limit reached ($MAX_DAILY_IMAGES accepted images); capture stopped."
    return 1
  fi
}

sleep_until_next_capture() {
  local started_at=$1 elapsed delay
  elapsed=$(($(date +%s) - started_at))
  if ((elapsed < INTERVAL)); then
    delay=$((INTERVAL - elapsed))
    log "Capture processed in ${elapsed}s; sleeping ${delay}s."
    sleep "$delay"
  else
    log "Warning: processing took ${elapsed}s, longer than the ${INTERVAL}s interval."
  fi
}

cleanup_temporary_files() {
  rm -f -- temp_image*.jpg current_hdr_image.tif current_movement_image.png .average.*
}
