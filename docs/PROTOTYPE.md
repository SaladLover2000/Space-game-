# Little Orbit — Playable prototype, Phases 1–2

A native Godot 4 / GDScript single-player study game. No internet, assets, or external libraries are required to play.

## Open and play on Windows

1. Install Godot 4.4 or newer, standard edition (no .NET required).
2. In the project manager choose **Import**, select `project.godot`, then **Import & Edit**.
3. Press **F6** with `scenes/main.tscn` open, or **F5** to run the project.
4. Choose **Begin your journey**, name your robot and ship, then start a session.
5. Choose 25/45/60/90/120 minutes or type a custom whole-minute duration from 1–240. A completed 25-minute session earns 50 credits: open **Repairs** to restore the engine. The engine room and exhaust visibly light up.
6. For a quick manual check use a custom **1 minute** session. Pause, resume, and try the compact window while studying in another application.
7. Click a room in the ship or use the room buttons. The view smoothly zooms in; select object buttons to inspect the room. Scroll down if necessary to see the full room panel. Choose **Back to overview** to zoom out.
8. Restore living quarters for 40 credits, the engine for 50, or the cockpit for 60. Each path is available immediately. View your companion's battery, expression and charging dock on **Robot**.

The compact timer is a separate native, always-on-top window. Closing it hides it; closing the main window exits and saves. The main window is resizable and its content scrolls on small displays. Names remain editable in Settings. Cancellation requires confirmation and awards no completion rewards.

## Included

- Main menu, first-run naming, overview/study screen, interactive room close-up, robot status, repair shop, study log, settings.
- Countdown based on monotonic elapsed milliseconds, independent of frame rate and system date changes; keeps counting while minimized. Pause/resume/cancel, reward estimates, completion chime and window attention request.
- Configurable credits (2/min), research XP (1/min), battery recharge (1%/min, capped at 100%). No passive depletion or missed-day penalties.
- Three room repairs with centralized prices, requirements, ownership, insufficient-funds handling and linked visual states. Existing Phase 1 saves remain compatible without migration.
- Original procedurally drawn pixel ship cutaway with three rooms, layered drifting stars and a dithered nebula. Rooms visibly lose rust and gain steady lighting as they are restored. The cockpit gains navigation lights and clean glass; quarters gain fresh bedding, a lamp and plant; the engine gains glowing coils and exhaust.
- Clickable rooms, hover outlines, smooth interruptible zoom, overview return, keyboard-accessible room and object buttons, and nine object descriptions that change with restoration.
- Robot sad/idle expressions, blinking, charging-dock pulses during running study, a four-second completion celebration and a brief repair reaction. Artwork is isolated and replaceable. Charging animation is cosmetic: battery rewards remain completion-only.
- Versioned JSON save, defaults, type validation, temporary-file replacement and validated previous-snapshot backup. Saves every ten seconds during sessions and on state changes/clean exit.

## Architecture and files

- `project.godot`, `scenes/main.tscn`: entry point and project configuration.
- `scripts/game.gd`: authoritative state, timer, transactions and persistence; autoloaded as Game.
- `data/balance.json`: reward rates and repair catalog.
- `data/rooms.json`: room bounds, names and damaged/restored inspection text.
- `ui/main.gd`: responsive screen composition, input, compact native window, sound.
- `assets/ship_view.gd`: original low-resolution drawing, no licensed third-party art.
- `tests/test_game.gd`: isolated headless logic and persistence checks.
- `tests/test_rooms.gd`: room click/zoom/inspection, restoration persistence, companion reactions and timer independence checks; optional graphical screenshot capture.
- `tests/test_minimized.gd`: real one-minute countdown acceptance test with a minimized native Windows window; takes about 65 seconds.

The UI requests operations from Game and never grants study rewards. Catalog IDs link ownership to art. Future components/rooms can extend the catalog and visual layer; planetary discoveries can be added with a versioned save migration and deterministic seed field.

## Persistence and timer policy

Saves live under `%APPDATA%\Godot\app_userdata\Little Orbit — Space Study\` (`orbit_v1.json` and `.bak`). On reopen, the most recent active checkpoint resumes **paused**. Closed-app time earns nothing; a crash can lose up to ten seconds of timer progress. Completion currency, history and session consumption are committed in one snapshot. Repeated callbacks cannot award a session twice. There is no claim-reward button.

This is an offline local game: deliberate save editing/rollback is outside the anti-exploit scope. The OS date is used only as a history label. System suspend behavior depends on the OS monotonic clock and is not a guarantee of active studying. Disk-write failures are shown in the UI; in-memory progress survives until exit but cannot survive an unwritable disk.

## Validation

From PowerShell, substituting the path to your Godot executable:

```powershell
& 'C:\Tools\Godot.exe' --headless --path . --editor --quit
& 'C:\Tools\Godot.exe' --headless --path . --script res://tests/test_game.gd
& 'C:\Tools\Godot.exe' --headless --path . --script res://tests/test_rooms.gd
& 'C:\Tools\Godot.exe' --headless --path . --script res://tests/test_ui.gd
```

The test uses a unique save filename and never writes to the player save. It covers invalid/overlapping sessions, long frame elapsed time, pause/cancel, rewards, repeat completion, purchase ownership, reload and corrupted-save recovery.

Manual acceptance: launch and name companions; complete a one-minute timer while minimized; hear chime and see resources; cancel another session for zero reward; reopen during a paused session; edit names; complete 25 minutes and repair engine; verify the restored art and ownership persist. Verify compact-window topmost behavior in Windows. Automated results for this delivery are recorded in `VALIDATION.md`.

## Scope and next task

This delivery includes the Phase 1 core and Phase 2 visual-restoration pass. Component customization, wishlist, technology tree, weekly bonuses, achievements, planets and solar-system editor remain deferred. Research XP is stored but the three starter repairs have no research gate. Artwork is still procedural placeholder art rather than a finished commissioned sprite set. No Windows executable is bundled yet.

Next: Phase 3 wishlist and a small set of visually distinct robot/ship components, followed by a Windows export and full manual acceptance pass. Keep timer and saves independent of presentation.

## Export

In Godot install matching export templates via **Editor → Manage Export Templates**. Open **Project → Export**, add **Windows Desktop**, choose x86_64 and a destination outside source (for example `build/LittleOrbit.exe`). Export a debug build first and run the manual acceptance checks above. Signing and installer packaging are future release work.
