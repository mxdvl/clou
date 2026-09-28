# Clou

A custom Garmin Connect IQ **watch face**, built with the Monkey C SDK.

Current state: concentric rings. Near the rim, the current time as an arc
between the (pinned) hour hand and the minute hand, which fills on one
65-minute lap and empties on the next, with a bar across the hour end and
stroke-drawn XII/III/VI/IX on its track. Inside it, the next sunrise or
sunset in the same style, then steps in the same
style, anchored at XII.
Named _clou_ ("nail" in French) — the hour hand is pinned in place, like a
nail through the dial. Formerly _boussole_ ("compass").

## Target devices

- `venu445mm` — Venu 4, 45 mm, 454 × 454 round AMOLED
- `fr970` — Forerunner 970, 454 × 454 round AMOLED

Install the device image for your target from the **Connect IQ SDK Manager → Devices** tab
before building/simulating.

## Prerequisites

Add both the JDK and the SDK to your `PATH`. The Homebrew OpenJDK 26 is
keg-only, and this SDK's tools run fine on it:

```fish
fish_add_path /opt/homebrew/opt/openjdk/bin
fish_add_path "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2/bin"
```

- The `venu445mm` or `fr970` device image, installed via **SDK Manager → Devices**.
- `developer_key.der` in the project root (already generated; git-ignored).

## Build & run

One command builds and side-loads into the simulator:

```sh
./run.sh          # Venu 4, 45 mm (default)
./run.sh fr970    # Forerunner 970
```

Both devices use the same layout and Always-On Display handling. To rebuild
and reload automatically when editing, run `./watch.sh fr970` (or `./watch.sh`
for the Venu 4).

Or manually:

```sh
mkdir -p bin
monkeyc -o bin/clou.prg -f monkey.jungle -y developer_key.der -d venu445mm -w -l 2
connectiq                       # launch the simulator (once)
monkeydo bin/clou.prg venu445mm
```

For the Forerunner 970, replace `venu445mm` with `fr970` in both commands.
Each build replaces `bin/clou.prg` with the version for the selected device.

In the simulator, pick a watch face via **Settings** if it doesn't show
automatically. Use **File → Time** to fast-forward the clock and watch the
hands move.

## Tests

Run the sunrise/sunset regression tests in the Connect IQ simulator using
the same SDK and signing-key prerequisites as a normal build:

```sh
mkdir -p bin/tests
monkeyc -o bin/tests/clou.prg -f monkey.jungle -y developer_key.der -d venu445mm -w -l 3 -t
connectiq
monkeydo bin/tests/clou.prg venu445mm -t
```

These tests cover advancing past sunset, selecting the following day's
sunrise across the spring clock change, polar day/night, and displaying
sun events in the watch's timezone across spring and autumn clock changes.
Garmin's `Time.Gregorian.info` converts the selected event to local time
using the watch's timezone rules for that date, independently of the GPS
location used to calculate sunrise and sunset.
The sunrise/sunset calculation itself now comes from Garmin's
on-device `Toybox.Weather.getSunrise`/`getSunset` (API Level 3.3.0), not
from code in this repo. Test code is excluded from normal and release builds.

Check both `Europe/London` and `UTC` to exercise a timezone with clock
changes and one without. On macOS, quit the simulator before each launch:

```sh
open -a "$(dirname "$(command -v connectiq)")/ConnectIQ.app" --env TZ=UTC
```

Run the tests, then repeat with `TZ=Europe/London`.

The next-day query aims near local noon to avoid skipping a date across
ordinary DST changes. Weather's use of the configured local date has been
verified in SDK 9.2.0's simulator; its date interpretation on physical
watch firmware remains unverified. This is not intended to handle
whole-day date-line changes.

## Release to the Connect IQ Store

One command builds the signed application package for every device listed in
`manifest.xml` (currently `venu445mm` and `fr970`) into a single file:

```sh
./release.sh
```

This produces `bin/clou-<tag>.iq` (e.g. `bin/clou-v0.0.1.iq`), named
after the most recent git tag reachable from `HEAD`
(`git describe --tags --abbrev=0`), ready to upload in the
[Connect IQ Developer Portal](https://developer.garmin.com/connect-iq/developer-tools/).
It's a release build (`-r`, debug info stripped) with strict type checking
(`-l 3`); test code is excluded, same as a normal build.

Tag a commit (`git tag -a vX.Y.Z -m "..."`) before running `./release.sh` to
version a release.

## Releasing from CI

[`.github/workflows/build.yml`](.github/workflows/build.yml) runs `release.sh`
on GitHub to build the store package, so a release's `.iq` always comes from
its tag rather than from a local checkout.

To release, tag the commit and push the tag:

```sh
git tag v0.0.2
git push origin v0.0.2
```

The workflow builds `clou-v0.0.2.iq` and creates a **draft** release for
the tag with the file attached and generated notes. Check the draft, edit the
notes, then publish it. Download the `.iq` from the release and upload it in
the Connect IQ developer dashboard (Garmin has no API for publishing, and
every version goes through their review anyway).

With **immutable releases** turned on (Settings → General → Releases), the
published release, its `.iq` and its tag can no longer change, so the file on
the release is exactly what was built from that tag. That's why the build
starts from the tag rather than from publishing a release: an immutable
release can't take new assets once published. To stop `v*` tags being moved
or deleted before they're released too, add a tag ruleset (Settings → Rules →
Rulesets) that blocks updates and deletions for `refs/tags/v*`.

On every push to `main`, the workflow runs the same build and keeps the `.iq`
as a workflow artifact. That checks each merge still compiles for every
device, and keeps the SDK and device downloads cached for the next release.

One-time setup, in the repository's **Settings → Secrets and variables →
Actions**:

| Secret | Value |
| --- | --- |
| `GARMIN_USERNAME` | Garmin account email (used to download the SDK and devices) |
| `GARMIN_PASSWORD` | its password; the SDK manager can't answer two-factor prompts |
| `CIQ_DEVELOPER_KEY` | `developer_key.der`, base64-encoded: `base64 -i developer_key.der \| pbcopy` |

Optionally, set the **variable** `CIQ_AGREEMENT_HASH` to the hash printed by
`connect-iq-sdk-manager agreement view`: the build then fails if Garmin changes
the licence agreement instead of accepting it silently.

Sign every release with the same developer key: the store rejects updates
signed with a different one.

## Install on the watch

The Venu 4 connects over USB as an MTP device, not as a drive, so macOS
Finder can't see it. Use [OpenMTP](https://openmtp.ganeshrvel.com/) to copy
files across.

1. Build a release `.prg` for the watch:

   ```sh
   mkdir -p bin
   monkeyc -o bin/clou.prg -f monkey.jungle -y developer_key.der -d venu445mm -r -w -l 3
   ```

   Use `-d fr970` instead when building for the Forerunner 970.

2. Plug the watch in with its USB cable and open **OpenMTP.app**. Quit Garmin
   Express first if it's running, since it can hold the connection.
3. In OpenMTP, the left pane is your Mac and the right pane is the watch. In
   the left pane go to this project's `bin/` folder; in the right pane go to
   `GARMIN/Apps`.
4. Drag `clou.prg` from the left pane into `GARMIN/Apps`, straight into
   that folder, not a subfolder. Replace the old copy if it asks. Leave the
   other `.prg` files there alone: they're your other installed apps.
5. Unplug the watch. It installs the file as it disconnects.
6. On the watch, long-press the watch face (or go to **Settings → Watch Face**)
   and pick **Clou**.

To update, rebuild and repeat steps 2–5: the new file replaces the old one.

## Editor support

Monkey C's full IntelliSense (completion, go-to-definition, inline API docs,
semantic type checking) is provided by Garmin's official **VS Code "Monkey C"
extension** — that's the paved-road editor experience.

In Zed there is no official Monkey C language server. Options:

- Install a community **Monkey C** extension from Zed's extensions panel
  (`zed: extensions`) for tree-sitter syntax highlighting, if available.
- Rely on **build-time type checking**: `monkeyc -l 2` (or `-l 3` for strict)
  reports type errors and warnings; `run.sh` uses `-l 2`.
- Keep VS Code + the CIQ extension around when you want deep IntelliSense,
  and do day-to-day editing in Zed.

## Assets / icons

Source art lives in `assets/` as SVG. Connect IQ can't use SVG directly, so
`icons.sh` rasterises it to the PNG drawables with [`resvg`](https://github.com/linebender/resvg):

```sh
./icons.sh        # regenerate launcher_icon.png from assets/logo.svg
./icons.sh 72     # at a specific pixel size
```

Re-run it whenever the SVGs change. The size is a placeholder until the Venu 4
launcher-icon dimensions are read from the installed device's `compiler.json`.

## Project layout

```
manifest.xml                     # app id, type=watchface, target products
monkey.jungle                    # build config
resources/strings/strings.xml    # app name
resources/drawables/             # launcher icon + drawable defs
source/ClouApp.mc            # Application entry point
source/ClouView.mc           # reads the device, builds the scene, renders it
source/Layout.mc                 # track radii and polar maths, from screen size
source/Shapes.mc                 # plain drawing records (Arc, Line, Dot)
source/Palette.mc                # named colours (craie, encre, brume)
source/ClockArc.mc               # pure: one time as an arc between the hands + hour bar
source/TimeRing.mc               # pure: current time, hour points, numerals; the Always-On scene
source/SunRing.mc                # pure: next sunrise or sunset as a clock arc
source/StepsRing.mc              # pure: steps ring, anchored at XII
source/Numerals.mc               # pure: roman numerals as strokes
source/SunCalc.mc                # next sun event, via Toybox.Weather (API 3.3.0+)
source/Render.mc                 # the only code that draws
```

## Always-On Display

While asleep on AMOLED devices with Always-On enabled, `ClouView` swaps
in the pared-back scene from `TimeRing.aodScene` (see its doc comment for
what changes and why).

Verified with the simulator's heat map (**File → View Screen Heat Map**):
no burn-in, peak luminance under 3%.

## Notes / next steps

- Nothing outstanding right now.
