# Project notes

## Purpose and model

This is an unattended Raspberry Pi photography pipeline, intended to be driven
by cron. Each HDR result is one statistical sample. Accepted samples form an
incremental arithmetic mean for the current day. At day end, that result is
exported and contributes 1/7 and 1/30 to exponential rolling images.

The key operational boundary is between capture and daily archiving. Those
processes mutate the same working files and must not overlap.

## 2026-07-11 review and hardening

Initial findings:

- Scripts only worked when launched from the repository directory.
- The default `TOPDIR` expanded to a malformed path with redundant leading
  slashes, and archive paths repeated that issue.
- Camera commands were strings executed with `eval`, making quoting fragile and
  allowing configuration text to be interpreted as arbitrary shell syntax.
- Missing globs made cleanup return errors; failures elsewhere were generally
  ignored, so corrupt or absent output could flow into the next stage.
- Capture and daily processing could run concurrently and overwrite shared
  images.
- Movement archiving was enabled in configuration and referenced by daily
  processing even though movement capture was commented out.
- The rolling weights were 1/6 and 1/29 rather than the documented 1/7 and 1/30.
- Email was unconditional, turning an optional delivery feature into a runtime
  dependency.
- `auth.json`, an unrelated local credential file, was untracked and not
  ignored. It was not read or modified; it is now explicitly ignored.

Changes made:

- Entry points now use strict Bash error handling and resolve their project and
  configuration paths independently of the caller's working directory.
- Centralized configuration validation, dependency checks, logging, safe
  cleanup, output verification, and workspace creation.
- Replaced evaluated command strings with `CAMERA_COMMAND` and `EXPOSURES`
  arrays.
- Added a non-blocking `flock` lock around capture and archive mutation.
- Persisted accepted-frame counts so restarting capture during a day does not
  accidentally give the first post-restart frame 100% weight.
- Made movement and email paths conditional and corrected archive naming.
- Corrected rolling weights to 7 and 30 samples and made generated state
  consistently ignored by Git.
- Replaced the brief historical README with setup, configuration, lifecycle,
  recovery, and cron documentation.

## Follow-up work

These items need real camera hardware or an explicit product decision:

1. Migrate the default camera configuration from legacy `raspistill` to
   `rpicam-still` for the Raspberry Pi OS version actually deployed.
2. Run a full sunrise-to-archive hardware soak test and record CPU temperature,
   processing time, storage growth, and failure behavior.
3. Decide whether the rolling output should remain an exponential moving
   average (current behavior) or become an exact window over the last 7/30 daily
   images. Exact windows require retaining and recomputing from daily sources.
4. Replace or remove `helper_installer.sh`. It performs a full OS upgrade and
   changes swap and boot settings based on an older Raspberry Pi OS layout.
5. Add automated image-fixture tests once representative camera frames can be
   committed or generated without exposing private scene data.

## Verification record

- Bash syntax validation: `bash -n` over all shell/config files.
- Patch whitespace validation: `git diff --check`.
- Mocked end-to-end daily archive run, including rolling blend output and all
  archive destinations.
- Hardware execution is still required; this development environment does not
  provide the configured Raspberry Pi camera or image-processing commands.
