# Phase 1 validation

Validated using Godot 4.4.1 stable on Windows, with app-data/cache paths redirected into the workspace for this restricted execution environment.

- Headless editor import: passed; no GDScript parse errors.
- Headless main-scene startup (120 frames): passed; no script/runtime errors.
- `tests/test_game.gd`: all 16 checks passed, zero failures. Includes long-frame elapsed time, pause, cancellation, overlapping-session rejection, completion rewards, repeat completion, purchase ownership, checkpoint reload, defaults and corrupted-save backup recovery.
- `tests/test_ui.gd`: passed through all screens, native compact-window construction, pause/resume, completion callback/audio setup, refreshed controls, and the restored shop.
- Graphical UI smoke test: passed on the OpenGL 3.3 compatibility renderer. Captured and inspected `prototype.png`; ship, companion, controls, resource status and reward estimate are visible without horizontal clipping at 1152×768.

Commands (from the project directory):

```powershell
& $Godot --headless --path . --editor --quit
& $Godot --headless --path . --script res://tests/test_game.gd
& $Godot --headless --path . --script res://tests/test_ui.gd
& $Godot --headless --path . --quit-after 120
& $Godot --path . --script res://tests/test_ui.gd -- --capture
```

Environment caveat: Godot reports that this sandbox cannot read the Windows root-certificate store; the game uses no network calls. The intentionally corrupted JSON test also emits the expected parser diagnostic before successfully loading the backup.

Not manually verified: a real full-minute session while minimized; audible output; topmost stacking against another application's window; suspend/resume; Windows export and launch of an exported executable. Automated time advancement verifies reward/timer logic, and the graphical smoke test verifies scene execution, but those checks do not replace these manual acceptance checks.
