#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=TimelapseFunctions.sh
source "$PROJECT_DIR/TimelapseFunctions.sh"

read_timelapse_config
prepare_workspace
acquire_capture_lock
require_command convert
require_command composite

[[ -f working_average_image.tif ]] || die "No daily average exists; run start_timelapse.sh first"

date_stamp=$(date +%Y-%m-%d)
daily_image="${LOCATION}_${date_stamp}.jpg"
weekly_image="${LOCATION}_${date_stamp}_7day.jpg"
monthly_image="${LOCATION}_${date_stamp}_30day.jpg"

log "Daily archive processing started."
convert working_average_image.tif -quality 100 "$daily_image"
cp -- "$daily_image" "$ARCHIVE/"
cp -- working_average_image.tif yesterday_average.tif

# Exponential rolling averages: today's image contributes 1/7 or 1/30.
make_average_image working_average_image.tif running_7day_average_image.tif 7
make_average_image working_average_image.tif running_30day_average_image.tif 30
convert running_7day_average_image.tif -quality 100 "$weekly_image"
convert running_30day_average_image.tif -quality 100 "$monthly_image"
cp -- "$weekly_image" "$ARCHIVE7/"
cp -- "$monthly_image" "$ARCHIVE30/"

attachments=("$daily_image" "$weekly_image")
if [[ "$MOVEMENT" == true && -f working_movement_average.tif ]]; then
  movement_image="${LOCATION}_${date_stamp}_movement.jpg"
  convert working_movement_average.tif -quality 100 "$movement_image"
  cp -- "$movement_image" "$ARCHIVEMOVEMENT/"
  attachments+=("$movement_image")
  rm -f -- working_movement_average.tif
fi

if [[ -n "$EMAIL" ]]; then
  require_command mpack
  for attachment in "${attachments[@]}"; do
    mpack -s "Timelapse image: $LOCATION $date_stamp" "$attachment" "$EMAIL"
  done
fi

rm -f -- "${attachments[@]}" "$monthly_image" working_average_image.tif "$COUNT_FILE" "$MOVEMENT_COUNT_FILE"
log "Daily archive processing finished."
