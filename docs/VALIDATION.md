# Phases 1–2 validation

Validated using Godot 4.4.1 stable on Windows, with app-data/cache paths redirected into the workspace for this restricted execution environment.

- Headless editor import: passed; no GDScript parse errors.
- Headless main-scene startup (120 frames): passed; no script/runtime errors.
- `tests/test_game.gd`: all 16 checks passed, zero failures. Includes long-frame elapsed time, pause, cancellation, overlapping-session rejection, completion rewards, repeat completion, purchase ownership, checkpoint reload, defaults and corrupted-save backup recovery.
- `tests/test_rooms.gd`: all 35 checks passed in graphical mode. Includes click hit-testing and object inspection in all three rooms, close-up and overview camera positions, rapid interrupted zooms, timer independence during room switches, insufficient funds, all three room purchases, save/reload, robot expression transitions and minimum-width layout.
- `tests/test_minimized.gd`: real-time native Windows check passed. Confirmed the window was minimized, completed a one-minute session after 60,005 ms, and observed exactly one completion and two credits. This test uses the running timer and does not simulate elapsed time.
- `tests/test_ui.gd`: passed through all screens, native compact-window construction, pause/resume, completion callback/audio setup, refreshed controls, and the restored shop.
- Graphical room test: passed on the OpenGL 3.3 compatibility renderer. Captured and inspected `prototype.png`, `engine-restored.png`, `minimum-window.png`, and `robot-status.png`. Overview study controls are above the ship art; room details scroll on smaller displays. Room layout also passes at a 920×680 logical canvas.

Commands (from the project directory):

```powershell
& $Godot --headless --path . --editor --quit
& $Godot --headless --path . --script res://tests/test_game.gd
& $Godot --headless --path . --script res://tests/test_ui.gd
& $Godot --headless --path . --script res://tests/test_rooms.gd
& $Godot --headless --path . --quit-after 120
& $Godot --path . --script res://tests/test_rooms.gd -- --capture
& $Godot --path . --script res://tests/test_minimized.gd
```

Environment caveat: Godot reports that this sandbox cannot read the Windows root-certificate store; the game uses no network calls. The intentionally corrupted JSON test also emits the expected parser diagnostic before successfully loading the backup.

Not manually verified: audible output; topmost stacking against another application's window; suspend/resume; Windows export and launch of an exported executable. The real-time minimized test verifies the running countdown on this Windows environment; it does not replace those remaining manual acceptance checks.
