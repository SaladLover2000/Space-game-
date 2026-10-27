# Phases 1–2 validation

## Larger window, name persistence and room-following fixes

The full strict graphical run passed **121 assertions** and editor import with no GDScript compile/runtime diagnostics. Per-suite results are in `usability-check-results.json`. This includes the existing 101 assertions plus 20 usability checks.

The new checks type names through the LineEdit text-change callbacks and read the actual isolated save file, then reload it. They cover autosave, setup completion, leaving Settings before the debounce fires, returning to Settings, and Enter-to-save. They also verify the 1600×900/maximized configuration, automatic robot arrival in every room, room/companion visibility inside the wider camera, latest-target behavior after rapid navigation, automatic hatch opening, and unchanged study timing.

`room-following.png` is an actual native render of the larger scene with persisted test names and the companion in the cockpit. The direct launcher path was checked against the installed Godot executable. The launcher itself has not been exercised against the player's real save during validation; automated suites use isolated saves. The embedded editor preview's own zoom setting remains an editor preference; `PLAY-GAME.cmd` bypasses it.

```powershell
python tests/run_checks.py --godot C:/Tools/Godot.exe --graphical --report usability-check-results.json
```

Validated using Godot 4.4.1 stable on Windows, with app-data/cache paths redirected into the workspace for this restricted execution environment.

- Headless editor import: passed; no GDScript parse errors.
- Headless main-scene startup (120 frames): passed; no script/runtime errors.
- `tests/test_game.gd`: all 25 checks passed, zero failures. Includes long-frame elapsed time, pause, cancellation, overlapping-session rejection, completion rewards, repeat completion before/after reload, affordable duplicate purchases, checkpoint reload, defaults, corrupted-save backup recovery, the one-millisecond completion boundary, battery cap, insufficient funds, unknown items, research gating and custom-duration boundaries.
- `tests/test_rooms.gd`: all 35 checks passed in graphical mode. Includes click hit-testing and object inspection in all three rooms, close-up and overview camera positions, rapid interrupted zooms, timer independence during room switches, insufficient funds, all three room purchases, save/reload, robot expression transitions and minimum-width layout.
- `tests/test_minimized.gd`: real-time native Windows check passed. Confirmed the window was minimized, completed a one-minute session after 60,005 ms, and observed exactly one completion and two credits. This test uses the running timer and does not simulate elapsed time.
- `tests/test_ui.gd`: all 10 explicit assertions passed. Checks naming, Start/Pause/Resume button callbacks against authoritative game state, overlapping-start prevention, compact-window configuration/hide/reopen, completion feedback and enabled controls. Screen creation is separately reported as smoke coverage. Failure counts determine process exit code; assertions are not disabled by release-mode settings.
- Graphical room test: passed on the OpenGL 3.3 compatibility renderer. Captured and inspected `prototype.png`, `engine-restored.png`, `minimum-window.png`, and `robot-status.png`. Overview study controls are above the ship art; room details scroll on smaller displays. Room layout also passes at a 920×680 logical canvas.

## Colorful drifting-space update

`tests/test_drift.gd` adds 13 motion assertions: bounded hull movement, hit testing on the moving hull, planet travel and different parallax speeds, exhaust movement/expansion/fade/recycling, exterior-screen status, running timer continuity and no scenery-driven progress changes. The native `--capture` run adds two real-frame checks: the scene clock advances over real time and rendered pixel data changes. These are separate from the existing 70 behavioral assertions (85 total in the graphical acceptance run).

The full 25 game, 35 room and 10 UI checks were rerun successfully. Native drift rendering was inspected in `drift-view.png`. Colorful scenery is original procedural art inspired by the supplied reference palettes; no supplied image pixels were imported into the game. Visual effects are decorative and do not implement planetary discovery.

```powershell
& $Godot --headless --path . --script res://tests/test_drift.gd
& $Godot --path . --script res://tests/test_drift.gd -- --capture
```

## Interior interaction update

The larger Interior screen uses original modular cutaway artwork with wall panels, recessed steel floors, a panoramic cockpit, twin console displays, a bunk and supply locker, coolant piping and two sliding bulkhead hatches. Drawn fixtures now have direct click regions. Inspector buttons remain available as an alternate input route. No movement, combat or time pressure is required. Door open/closed state is transient visual state; room restoration remains persistent.

`tests/test_interior.gd` passed 16 assertions in a native graphical run: all nine equipment clicks, the correct hatch toggling, closed/open animation endpoints, rapid reversal, progress isolation, timer continuity and repair-aware equipment descriptions. Existing game/UI/room/drift suites were rerun (25 + 10 + 35 + 15), for 101 behavioral/render assertions across the current suites. Screenshots `interior-damaged.png`, `interior-restored.png` and `quarters-closeup.png` were captured and inspected.

```powershell
& $Godot --path . --script res://tests/test_interior.gd -- --capture
```

## Hull and articulated companion art pass

The exterior and cutaway now share a chamfered, swept hull with forward strakes, tall aft stabilizers, layered armor and two engine pods. White exhaust originates from both nozzles. The companion sprite has a distinct visor/helmet, neck spindle, tapered breastplate, shoulder and elbow joints, grippers, hips, piston legs and separate feet. Robot status includes a larger live portrait using the same artwork and expression source as the room sprite.

`tests/run_checks.py --graphical` passed editor import and all 101 existing behavioral/render assertions with **no GDScript compile/runtime errors**. Current screenshots were regenerated and inspected. Detailed per-suite results are in `shape-check-results.json`.

During the first art import a GDScript type-inference error was found and fixed. Godot still returned exit code zero and some scene assertions continued, demonstrating that a successful engine exit or assertion summary alone is insufficient. The new strict runner checks captured engine diagnostics as well as suite exit codes and result markers. An intentionally malformed robot script in an isolated project copy was rejected by this runner with exit code 1 even though the underlying Godot import returned 0. Evidence is in `runner-negative-result.json`; the actual source project was not modified by this negative check.

```powershell
python tests/run_checks.py --godot $Godot --graphical --report shape-check-results.json
```

## Earlier test audit details

There are 70 behavioral assertions across the game (25), room (35) and UI (10) suites. Game tests execute the actual autoload, not a replacement implementation. Fast timer tests inject monotonic timestamps into the same `advance()` method used by the running game; this is controlled-clock unit testing, not a real-time/minimized-window test. Save tests read/write real isolated files. Room tests run actual tweens and inspection callbacks. UI button tests emit Godot button signals to exercise connected actions; they do not simulate physical mouse/keyboard events or validate OS-level input routing.

`tests/mutation_check.py` copies the project into temporary directories beneath the explicitly supplied scratch directory, deliberately changes production code there, and runs the normal test suites. Five deliberate defects are checked with nonzero exit codes and expected behavioral assertion failures (not parse errors or crashes): a hatch toggle that does nothing; doubled completion credits; countdown continuing while paused; duplicate purchases with sufficient funds; disconnected Pause button. The source project and player saves are not modified. Results are in `mutation-results.json`.

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
