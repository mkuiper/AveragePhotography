# AveragePhotography

AveragePhotography creates long-exposure-style timelapses on a Raspberry Pi by
averaging many HDR frames. Transient objects such as pedestrians and cars become
faint or disappear, while stationary parts of the scene remain.

The pipeline has two phases:

1. `start_timelapse.sh` repeatedly captures an exposure bracket, merges it with
   `enfuse`, rejects frames outside configured light limits, and adds accepted
   frames to the current daily average.
2. After stopping capture, `image_averaging.sh` exports that daily image and
   updates exponential 7-day and 30-day averages.

Runtime images, logs, and pause/lock files are intentionally ignored by Git.

## Requirements

- Bash 4 or newer
- A Raspberry Pi camera command (the default configuration uses legacy
  `raspistill`)
- `enfuse`
- ImageMagick (`convert` and `composite`)
- `flock` (normally supplied by `util-linux`)
- Optional: `mpack` for email and `tvservice` for legacy HDMI power control

Modern Raspberry Pi OS uses `rpicam-still`; its options differ from
`raspistill`, so update `CAMERA_COMMAND`, `EXPOSURE_FLAG`, and `EXPOSURES` for
the installed camera stack. `helper_installer.sh` is retained as a historical
Raspberry Pi OS installer but should be reviewed before use because it upgrades
the operating system and edits boot/swap configuration.

## Configuration

Edit `Timelapse_Config.txt`. It is Bash syntax, so array values must remain in
parentheses and paths containing spaces must be quoted.

The most important settings are:

- `TOPDIR`: runtime working directory and archive parent. It defaults to the
  repository directory.
- `CAMERA_COMMAND`: command and fixed camera options as a Bash array.
- `EXPOSURES`: exposure compensation values captured for each HDR frame.
- `INTERVAL`: seconds from the start of one capture cycle to the next.
- `LIGHT_LOWER` / `LIGHT_UPPER`: accepted mean brightness on a 0–255 scale.
- `MOVEMENT`: additionally archive differences from yesterday's average.
- `EMAIL`: recipient for daily output; leave empty to disable email.

The scripts resolve configuration relative to their own location, so cron does
not need to set a working directory. To use another configuration without
changing the repository, set an absolute path in `TIMELAPSE_CONFIG`:

```bash
TIMELAPSE_CONFIG=/home/pi/timelapse.conf ./start_timelapse.sh
```

Keep configurations containing credentials outside version control.

## Operation

First test the configured camera command manually. Then start capture:

```bash
./start_timelapse.sh
```

Request a graceful stop from another terminal or cron job:

```bash
./stop_timelapse.sh
```

The capture process notices the pause file after its current cycle. Wait for it
to exit, then create the daily archives:

```bash
./image_averaging.sh
```

A file lock prevents capture and daily archiving from running concurrently.
Starting either operation while the other holds the lock exits with an error.

Example cron schedule (adjust paths and times):

```cron
0 6 * * * /home/pi/AveragePhotography/start_timelapse.sh
0 20 * * * /home/pi/AveragePhotography/stop_timelapse.sh
5 20 * * * /home/pi/AveragePhotography/image_averaging.sh
```

Five minutes is only an example: allow enough time for the final capture cycle
to finish. Logs are written to `$TOPDIR/log_file.txt`; the most recent frame
status is in `$TOPDIR/last_message.txt`.

## Safety and recovery

- Run only one camera pipeline for a given `TOPDIR`.
- Do not run daily archiving until capture has stopped.
- If capture is interrupted, temporary inputs are removed automatically; the
  completed daily average and its sample count remain available for an accurate
  later restart or archive.
- If a stale `.capture.lock` file remains after a crash, it is harmless. `flock`
  locks the open file descriptor, not the file's mere presence.
- Back up the archive directories independently. Generated images are ignored
  by Git and are not part of repository history.

See `PROJECT_NOTES.md` for the code review, decisions, and follow-up work.
