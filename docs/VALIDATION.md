# Phases 1–2 validation

Validated using Godot 4.4.1 stable on Windows, with app-data/cache paths redirected into the workspace for this restricted execution environment.

- Headless editor import: passed; no GDScript parse errors.
- Headless main-scene startup (120 frames): passed; no script/runtime errors.
- `tests/test_game.gd`: all 25 checks passed, zero failures. Includes long-frame elapsed time, pause, cancellation, overlapping-session rejection, completion rewards, repeat completion before/after reload, affordable duplicate purchases, checkpoint reload, defaults, corrupted-save backup recovery, the one-millisecond completion boundary, battery cap, insufficient funds, unknown items, research gating and custom-duration boundaries.
- `tests/test_rooms.gd`: all 35 checks passed in graphical mode. Includes click hit-testing and object inspection in all three rooms, close-up and overview camera positions, rapid interrupted zooms, timer independence during room switches, insufficient funds, all three room purchases, save/reload, robot expression transitions and minimum-width layout.
- `tests/test_minimized.gd`: real-time native Windows check passed. Confirmed the window was minimized, completed a one-minute session after 60,005 ms, and observed exactly one completion and two credits. This test uses the running timer and does not simulate elapsed time.
- `tests/test_ui.gd`: all 10 explicit assertions passed. Checks naming, Start/Pause/Resume button callbacks against authoritative game state, overlapping-start prevention, compact-window configuration/hide/reopen, completion feedback and enabled controls. Screen creation is separately reported as smoke coverage. Failure counts determine process exit code; assertions are not disabled by release-mode settings.
- Graphical room test: passed on the OpenGL 3.3 compatibility renderer. Captured and inspected `prototype.png`, `engine-restored.png`, `minimum-window.png`, and `robot-status.png`. Overview study controls are above the ship art; room details scroll on smaller displays. Room layout also passes at a 920×680 logical canvas.

## Test audit and deliberate-failure verification

There are 70 behavioral assertions across the game (25), room (35) and UI (10) suites. Game tests execute the actual autoload, not a replacement implementation. Fast timer tests inject monotonic timestamps into the same `advance()` method used by the running game; this is controlled-clock unit testing, not a real-time/minimized-window test. Save tests read/write real isolated files. Room tests run actual tweens and inspection callbacks. UI button tests emit Godot button signals to exercise connected actions; they do not simulate physical mouse/keyboard events or validate OS-level input routing.

`tests/mutation_check.py` copies the project into temporary directories beneath the explicitly supplied scratch directory, deliberately changes production code there, and runs the normal test suites. Four of four deliberate defects were rejected with nonzero exit codes and the expected behavioral assertion failures (not parse errors or crashes): doubled completion credits; countdown continuing while paused; duplicate purchases with sufficient funds; disconnected Pause button. The source project and player saves were not modified. Results are in `mutation-results.json`.

This demonstrates that these assertions detect those specific regressions. It is not a claim of exhaustive coverage, visual correctness, audible output or full end-to-end mouse interaction.

Commands (from the project directory):

```powershell
& $Godot --headless --path . --editor --quit
& $Godot --headless --path . --script res://tests/test_game.gd
& $Godot --headless --path . --script res://tests/test_ui.gd
& $Godot --headless --path . --script res://tests/test_rooms.gd
& $Godot --headless --path . --quit-after 120
& $Godot --path . --script res://tests/test_rooms.gd -- --capture
& $Godot --path . --script res://tests/test_minimized.gd
python tests/mutation_check.py --godot $Godot --scratch C:/Temp/orbit-tests --report mutation-results.json
```

Environment caveat: Godot reports that this sandbox cannot read the Windows root-certificate store; the game uses no network calls. The intentionally corrupted JSON test also emits the expected parser diagnostic before successfully loading the backup.

Not manually verified: audible output; topmost stacking against another application's window; suspend/resume; Windows export and launch of an exported executable. The real-time minimized test verifies the running countdown on this Windows environment; it does not replace those remaining manual acceptance checks.
