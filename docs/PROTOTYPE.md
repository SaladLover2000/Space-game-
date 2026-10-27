# Little Orbit — Phase 1

A native Godot 4 / GDScript single-player study game. No internet, assets, or external libraries are required to play.

## Open and play on Windows

1. Install Godot 4.4 or newer, standard edition (no .NET required).
2. In the project manager choose **Import**, select `project.godot`, then **Import & Edit**.
3. Press **F6** with `scenes/main.tscn` open, or **F5** to run the project.
4. Choose **Begin your journey**, name your robot and ship, then start a session.
5. Choose 25/45/60/90/120 minutes or type a custom whole-minute duration from 1–240. A completed 25-minute session earns 50 credits: open **Repairs** to restore the engine. The engine room and exhaust visibly light up.
6. For a quick manual check use a custom **1 minute** session. Pause, resume, and try the compact window while studying in another application.

The compact timer is a separate native, always-on-top window. Closing it hides it; closing the main window exits and saves. The main window is resizable and its content scrolls on small displays. Names remain editable in Settings. Cancellation requires confirmation and awards no completion rewards.

## Included

- Main menu, first-run naming, overview/study screen, repair shop, study log, settings.
- Countdown based on monotonic elapsed milliseconds, independent of frame rate and system date changes; keeps counting while minimized. Pause/resume/cancel, reward estimates, completion chime and window attention request.
- Configurable credits (2/min), research XP (1/min), battery recharge (1%/min, capped at 100%). No passive depletion or missed-day penalties.
- Single engine repair with centralized price, requirements, ownership, insufficient-funds handling and linked visual state.
- Original procedurally drawn pixel ship cutaway with three rooms, drifting stars, robot idle/blink animation and battery-sensitive eyes. Artwork is isolated and replaceable.
- Versioned JSON save, defaults, type validation, temporary-file replacement and validated previous-snapshot backup. Saves every ten seconds during sessions and on state changes/clean exit.

## Architecture and files

- `project.godot`, `scenes/main.tscn`: entry point and project configuration.
- `scripts/game.gd`: authoritative state, timer, transactions and persistence; autoloaded as Game.
- `data/balance.json`: reward rates and repair catalog.
- `ui/main.gd`: responsive screen composition, input, compact native window, sound.
- `assets/ship_view.gd`: original low-resolution drawing, no licensed third-party art.
- `tests/test_game.gd`: isolated headless logic and persistence checks.

The UI requests operations from Game and never grants study rewards. Catalog IDs link ownership to art. Future components/rooms can extend the catalog and visual layer; planetary discoveries can be added with a versioned save migration and deterministic seed field.

## Persistence and timer policy

Saves live under `%APPDATA%\Godot\app_userdata\Little Orbit — Space Study\` (`orbit_v1.json` and `.bak`). On reopen, the most recent active checkpoint resumes **paused**. Closed-app time earns nothing; a crash can lose up to ten seconds of timer progress. Completion currency, history and session consumption are committed in one snapshot. Repeated callbacks cannot award a session twice. There is no claim-reward button.

This is an offline local game: deliberate save editing/rollback is outside the anti-exploit scope. The OS date is used only as a history label. System suspend behavior depends on the OS monotonic clock and is not a guarantee of active studying. Disk-write failures are shown in the UI; in-memory progress survives until exit but cannot survive an unwritable disk.

## Validation

From PowerShell, substituting the path to your Godot executable:

```powershell
& 'C:\Tools\Godot.exe' --headless --path . --editor --quit
& 'C:\Tools\Godot.exe' --headless --path . --script res://tests/test_game.gd
```

The test uses a unique save filename and never writes to the player save. It covers invalid/overlapping sessions, long frame elapsed time, pause/cancel, rewards, repeat completion, purchase ownership, reload and corrupted-save recovery.

Manual acceptance: launch and name companions; complete a one-minute timer while minimized; hear chime and see resources; cancel another session for zero reward; reopen during a paused session; edit names; complete 25 minutes and repair engine; verify the restored art and ownership persist. Verify compact-window topmost behavior in Windows. Automated results for this delivery are recorded in `VALIDATION.md`.

## Scope and next task

This delivery intentionally stops at Phase 1. No room inspection/zoom, component customization, wishlist, technology tree, weekly bonuses, achievements, planets, or solar-system editor. Research XP is stored but the first repair has no research gate. The robot has basic idle/low-battery expression; charging/celebration and detailed component animations belong to Phase 2. No Windows executable is bundled yet.

Next: Phase 2 clickable room scenes with animated zoom, richer damaged/restored assets and charging/celebration expressions. Keep timer and saves independent of room scenes.

## Export

In Godot install matching export templates via **Editor → Manage Export Templates**. Open **Project → Export**, add **Windows Desktop**, choose x86_64 and a destination outside source (for example `build/LittleOrbit.exe`). Export a debug build first and run the manual acceptance checks above. Signing and installer packaging are future release work.
