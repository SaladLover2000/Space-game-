# Little Orbit — Playable prototype, Phases 1–2

A native Godot 4 / GDScript single-player study game. No internet, assets, or external libraries are required to play.

## Open and play on Windows

For the larger standalone window on this PC, double-click `PLAY-GAME.cmd` in the project root. It uses the Godot executable already extracted in Downloads and starts the game maximized with a 1600×900 design canvas. This avoids the small embedded preview shown inside the editor. Stop any existing run before starting it. Godot's editor can still launch the project with F5.

Names now autosave after a short typing pause, on leaving the form, and on clean exit. Enter or the form button saves and continues. New-game setup is marked complete only by continuing. A failed save is shown on the form rather than reporting success.

Room selection keeps the complete 280×150 ship view at the same scale. The inspector no longer stretches the drawing area and enlarges the ship. A cyan outline identifies the selected room while its equipment appears in the inspector. Selecting a room automatically moves the companion into it with a stepping animation. Hatches on the route open automatically; this requires no player movement input and changes no study rewards.

1. Install Godot 4.4 or newer, standard edition (no .NET required).
2. In the project manager choose **Import**, select `project.godot`, then **Import & Edit**.
3. Press **F6** with `scenes/main.tscn` open, or **F5** to run the project.
4. Choose **Begin your journey**, name your robot and ship, then start a session.
5. Choose 25/45/60/90/120 minutes or type a custom whole-minute duration from 1–240. A completed 25-minute session earns 50 credits: open **Repairs** to restore the engine. The engine room and exhaust visibly light up.
6. For a quick manual check use a custom **1 minute** session. Pause, resume, and try the compact window while studying in another application.
7. Click a room in the ship or use the room buttons. The full ship remains visible and the room is highlighted; select equipment in the scene or its buttons to inspect it. Scroll down if necessary to see the full room panel. Choose **Back to overview** to clear the selection.
8. Restore living quarters for 40 credits, the engine for 50, or the cockpit for 60. Each path is available immediately. View your companion's battery, expression and charging dock on **Robot**.
9. Open **Drift** for a colorful exterior view: the hull gently rocks, soft white exhaust disperses, and shaded orange, turquoise and violet planets pass at different speeds. Your running study session continues and its status stays visible. Return to **Ship & study** to use the timer controls.
10. Open **Interior** for the larger ship cutaway. Pick a room, then click the drawn equipment itself or its corresponding inspector button. Click either bulkhead hatch (or its sidebar button) to slide its shutters open/closed. Hatches are optional visual interactions and reset open when the view is recreated; purchased restoration states remain saved.

The compact timer is a separate native, always-on-top window. Closing it hides it; closing the main window exits and saves. The main window is resizable and its content scrolls on small displays. Names remain editable in Settings. Cancellation requires confirmation and awards no completion rewards.

## Included

- Main menu, first-run naming, overview/study screen, whole-ship room inspector, robot status, repair shop, study log, settings.
- Countdown based on monotonic elapsed milliseconds, independent of frame rate and system date changes; keeps counting while minimized. Pause/resume/cancel, reward estimates, completion chime and window attention request.
- Configurable credits (2/min), research XP (1/min), battery recharge (1%/min, capped at 100%). No passive depletion or missed-day penalties.
- Three room repairs with centralized prices, requirements, ownership, insufficient-funds handling and linked visual states. Existing Phase 1 saves remain compatible without migration.
- Original procedurally drawn pixel ship cutaway with three rooms, layered drifting stars and a dithered nebula. Rooms visibly lose rust and gain steady lighting as they are restored. The cockpit gains navigation lights and clean glass; quarters gain fresh bedding, a lamp and plant; the engine gains glowing coils and exhaust.
- Clickable rooms, hover/selection outlines, stable overview framing, keyboard-accessible room and object buttons, and nine object descriptions that change with restoration.
- Robot sad/idle expressions, blinking, charging-dock pulses during running study, a four-second completion celebration and a brief repair reaction. Artwork is isolated and replaceable. Charging animation is cosmetic: battery rewards remain completion-only.
- Versioned JSON save, defaults, type validation, temporary-file replacement and validated previous-snapshot backup. Saves every ten seconds during sessions and on state changes/clean exit.

## Architecture and files

- `project.godot`, `scenes/main.tscn`: entry point and project configuration.
- `scripts/game.gd`: authoritative state, timer, transactions and persistence; autoloaded as Game.
- `data/balance.json`: reward rates and repair catalog.
- `data/rooms.json`: room bounds, names and damaged/restored inspection text.
- `ui/main.gd`: responsive screen composition, input, compact native window, sound.
- `assets/ship_view.gd`: original low-resolution drawing, no licensed third-party art.
- `assets/space_backdrop.gd`: original seeded nebula and shaded planet textures; parallax scenery. User references informed the palette only; no reference image pixels or watermarks are bundled.
- `assets/interior_art.gd`: modular wall/floor tiling, cockpit workstation, recessed bunk, locker, coolant system and animated bulkheads. Original code-drawn art inspired by the interior references; no third-party sprite sheet copied or embedded.
- `assets/hull_art.gd`: shared shaped hull, swept stabilizers, forward strakes, chamfered cockpit, armor plates and twin engine pods. Exterior and cutaway share the same chassis; both retain white exhaust.
- `assets/robot_art.gd`: articulated robot with helmet/visor, neck, tapered torso, shoulder/elbow joints, two-finger grippers, hip linkage, piston legs and distinct feet. Expressions still follow battery, study and repair/completion events.
- `assets/robot_portrait.gd`: larger companion portrait on Robot status, drawn from the same robot artwork as the in-room companion.
- `tests/test_interior.gd`: all nine in-room fixture hit tests, hatch shutter behavior, repair-aware inspection and isolation from study/save progress.
- `tests/test_drift.gd`: motion, exhaust lifetime, moving-hull hit tests, scenery/timer isolation and optional real-frame render comparisons.
- `tests/test_game.gd`: isolated headless logic and persistence checks.
- `tests/test_rooms.gd`: room click/zoom/inspection, restoration persistence, companion reactions and timer independence checks; optional graphical screenshot capture.
- `tests/test_minimized.gd`: real one-minute countdown acceptance test with a minimized native Windows window; takes about 65 seconds.
- `tests/mutation_check.py`: verifies the suites reject five deliberately introduced regressions in isolated project copies; standard Python only.
- `tests/run_checks.py`: runs import and the full regression suite; rejects GDScript errors even if Godot reports exit code zero. Use `--graphical` to capture current game screens and check native rendered-frame animation.
- `tests/test_usability.gd`: actual file persistence for typed names, Enter/navigation save paths, window configuration, full-room framing, companion arrival/visibility, rapid room changes and timer continuity.

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

Preferred full regression command (Python standard library only):

```powershell
python tests/run_checks.py --godot 'C:\Tools\Godot.exe' --graphical --report check-results.json
```

Manual acceptance: launch and name companions; complete a one-minute timer while minimized; hear chime and see resources; cancel another session for zero reward; reopen during a paused session; edit names; complete 25 minutes and repair engine; verify the restored art and ownership persist. Verify compact-window topmost behavior in Windows. Automated results for this delivery are recorded in `VALIDATION.md`.

## Scope and next task

This delivery includes the Phase 1 core and Phase 2 visual-restoration pass. A first ship workshop is included. Wishlist, technology tree, weekly bonuses, achievements, collectible planets and solar-system editor remain deferred. Research XP is stored but the three starter repairs have no research gate. Artwork is still procedural placeholder art rather than a finished commissioned sprite set. No Windows executable is bundled yet.

The colorful planet fly-bys in Drift and room backgrounds are decorative scenery. Collectible discoveries, planet interaction and solar-system construction remain deferred. White exhaust is an atmospheric visual effect even before engine restoration; repaired engines emit a denser trail. Ship drift is cosmetic and never changes study rewards or battery use.

Next: wishlist and robot components, followed by a Windows export and full manual acceptance pass. Keep timer and saves independent of presentation.

## Export

In Godot install matching export templates via **Editor → Manage Export Templates**. Open **Project → Export**, add **Windows Desktop**, choose x86_64 and a destination outside source (for example `build/LittleOrbit.exe`). Export a debug build first and run the manual acceptance checks above. Signing and installer packaging are future release work.

## Ship workshop and side-view themes

Open **Shop** to select a ship component directly on the preview or choose a category. There are 21 designs across seven slots: engines, hull, fins/solar, paint, sensors, lighting and interior. Preview changes only the displayed ship. Buy & equip deducts credits once; owned designs can be swapped freely. Research XP gates some designs but is not spent. Equipped designs persist across restarts.

The cutaway now has taller side walls and a narrow deck for a clearer side-on view. Industrial steel is the free original theme; Warm habitat adds bronze walls and amber lamps; Cyan laboratory adds cool panels and a glass tower. Select **Shop → Interior themes** to preview them. Room selection keeps the entire ship visible and the robot walks to the selected room.

An engine patch costs 10 credits and restores 25 condition points, capped at 100%. A full overhaul costs 50 credits, restores 100%, and unlocks replacement engines. Patching does not grant overhaul ownership. Four patches can fill condition, after which an overhaul can still unlock replacements. Automatic asteroid damage is not implemented; condition never degrades as a study penalty. These components are cosmetic, not combat statistics.

Old saves gain stock equipment automatically. Invalid, unowned or mismatched equipment IDs reset to the correct stock part. Workshop purchases and equipment changes roll back if saving fails. A successful retry clears the storage error notice. Test screenshots use isolated demonstration saves, not player progress.