# Current validation - 2026-10-28

The strict headless runner passed editor import and **318 assertions across 14 suites**, with no GDScript compile/runtime errors. Current report: diorama-damage-check-results.json. Historical entries below describe earlier builds and are superseded by this milestone.

The 27-check expedition suite verifies prerequisite and affordability gates, no double charges, save-failure rollback, actual Build callbacks, preview isolation, construction/research disk reload, connected lower-deck routes, hatch blocking, return to the pilot chair, bridge software state, real mesh construction, eight separate pixel-art angles, camera-only orbit input and the optional researched scanner.

The 29-check focus/cruise suite verifies blank/whitespace task rejection, safe legacy checkpoint resumption, actual task/Start callbacks, hidden shop timer with uninterrupted elapsed focus time, side-panel shop structure, Robot-tab upgrade access, compact dock layout against active font metrics, clean ASCII status text, steady default lights, glancing/missed contacts, contact-time/idempotent minor hull damage, non-destructive hull floor, patch costs/save rollback, free robot repairs, planet motion and manual-over-autonomous activity priority.

Existing reward, pause/cancel, naming, backup recovery, repair/part purchasing, atlas calibration, 243 robot combinations, seat poses, click-vs-drag and camera zoom checks passed. Test fixtures now name their focus task explicitly because production defaults intentionally reject anonymous sessions. Minimum-width checks reflect the revised 16-pixel margins. Headless font metrics differ from the normal rendered font; the dock height budget accounts for measured line height rather than claiming rendered pixel-fit acceptance.

No visible game was launched. The new generated cockpit, room-module and pixel-angle asset files were visually inspected, including corrected atlas spacing. Assembled layout, GPU output, physical OS mouse routing and motion comfort have not been visually accepted. Existing gameplay screenshots are historical. No screenshot is claimed for this milestone. See GROWING-STARSHIP.md and UI-REFERENCES.md for behavior, sources and exact asset/prompt paths.

---
# Phases 1–2 validation

## Whole-ship selection and detailed body update

Room selection now retains the exact 280×150 overview camera. The ship drawing area's height is also kept independent of the inspector, eliminating the indirect enlargement caused by a taller selection panel. The selected room receives a cyan outline; its inspector and the companion follow the selection.

The hull has distinct raised bridge and reactor volumes around a narrower waist, separate belly plates, frame collars, service lines, radiator vanes, docking sockets, navigation lights and a small communications dish. Exterior panels distinguish living quarters from the reactor access casing. Cutaway views share this shaped chassis rather than a continuous rectangular outer border.

The strict graphical run passed editor import and **124 assertions** with no script errors (25 game + 10 UI + 35 rooms + 16 interior + 15 drift + 23 usability). The three added assertions verify actual rendered transform scale stays unchanged after selecting each room, in addition to full camera bounds and robot visibility. Results are in `full-ship-check-results.json`; current screenshots were regenerated and inspected.

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

## Workshop and side-view theme validation

The strict graphical runner passed **162 assertions** across seven suites plus editor import, with no GDScript compile/runtime errors. See `workshop-check-results.json` for current results. The workshop suite contributes 38 checks covering affordability, engine prerequisites, XP gates, one-time charges, free equipment swaps, disk reload, invalid equipment migration, failed-save rollback and recovery, actual component hotspot callbacks and Buy button actions, non-persistent previews, theme persistence, timer continuity and the narrow-window card layout.

Actual runtime captures: `ship-workshop.png`, `shop-parts-catalog.png`, `interior-theme-preview.png`, `interior-lab-preview.png` and `side-view-habitat.png`. These use isolated demonstration saves. The checks exercise connected Godot signals and real state/save logic, not physical mouse automation. Original procedural artwork is used; no reference screenshot sprites were embedded. Automatic asteroid collisions and a finished exported Windows executable remain outside this delivery.

## Ship detail pass

Added original hull service structure, dorsal radiator, cargo locks, layered nose plating, access panels, fin hydraulics, engine clamps and feed lines. Interior fittings include cable trays, vents, switchgear and reactor gauges. The strict graphical runner passed all 162 existing behavioral/render assertions without script errors; screenshots were regenerated and visually inspected. See detail-check-results.json. No new logic tests were added for decorative drawing code.

## Robot store, camera controls and in-game timer

Current strict **headless** run: editor import plus 195 passing behavioral assertions across eight suites, with no script errors. See robot-zoom-check-results.json. The new 28-check suite exercises actual robot shop category/Preview/Buy callbacks, affordability, research gates, duplicate purchase prevention, free swapping, real disk reload, failed-save rollback, mouse-wheel input, zoom limits and preservation on room selection, restoration/alarm state, and timer navigation/hiding/reopening without creating Window nodes. The usability suite additionally checks closed-door collision in both directions, waiting for opening clearance, closing during approach and resuming the pending route.

This run launched no visible game windows. The latest wing, room-damage and robot-equipment artwork has not yet received a graphical capture or visual review; existing PNG files predate this pass. A request to open the game for new screenshots is pending user permission. The timer is now an in-game PanelContainer, replacing the former native always-on-top window. No automated graphical tests should be run without user permission.

## Detailed raster ship validation

The current strict headless runner passed editor import and **208 assertions** across nine suites with no script errors. See pixel-art-check-results.json. New checks verify all three sprite states have matching atlas dimensions and usable alpha, each repaired room selects its own restored artwork, the reactor states differ, the deck and passage columns align with the robot and blocking hatches, the fitted camera contains the full atlas, and exhaust comes from the new aft nozzles. Existing purchase, persistence, robot upgrade, timer, wheel zoom and hatch movement checks passed unchanged. The earlier robot-only headless count was 195, not 197; the report was authoritative.

Generated asset images were inspected. The assembled game has not been visually reviewed or captured because no visible game launch is authorized. Existing PNG screenshots are historical; assets/art PNGs are the new sprite assets.


## Interchangeable raster robot validation

The current strict headless runner passed editor import and **221 assertions** across ten suites with no script errors. See modular-robot-check-results.json. New tests enumerate all 243 outfits, verify the seven rendered layers select their actual equipment IDs, check neck/hip connections and floor alignment, verify the common portrait stage contains every idle outfit, compare wider/taller dimensions, verify unchanged arms move with a broader chassis and that long legs raise the existing torso/head, check twenty-one nonempty atlas regions, exercise real shop height preview without changing progress, and verify persisted dimensions and size-aware hatch blocking/resumption.

The new parts atlas was visually inspected. The assembled robot in the running game has not been visually captured or reviewed; all testing remained headless in accordance with the user's instruction. Existing screenshots still show earlier robot artwork.


## Pilot seating and left-mouse panning

The strict headless runner passed editor import and **244 assertions** across eleven suites with no script errors. See seat-pan-check-results.json. The new 23-check suite drives the actual GUI press, motion and release callbacks: diagonal pan, suppression of chair/hatch/shop clicks during drag, release outside the canvas, lost-button cancellation, pan-preserving zoom/room selection and Fit ship reset. It also tests blocked seating routes through both hatches, arrival-only seating, articulated seated limbs, hip alignment for all three leg styles, description-refresh isolation, actual Stand up and Pilot seat button callbacks, room-follow resumption and unchanged session/progress state.

Existing fixture/hotspot tests now send complete press/release clicks because actions deliberately occur after release. These are production callback tests, not OS-level mouse automation. No visible game window was opened or captured; the assembled seated pose still needs graphical acceptance review.


## Shared-space damaged-angle validation

The new 18-check diorama suite verifies use of the same backdrop class and planet trajectory as the side view, camera pan/reset, time-dependent drift, transparent optional mesh viewport configuration, registered alpha/damaged atlas differences, default broken-system selection, per-repair overlays, actual engine-fault mesh removal, saved restoration reload, patch bounds for all eight angles, clean full-restoration state and separate minor hull wear. The complete strict headless regression passed 318 assertions plus editor import with no script errors. No game window was opened; actual rendered background compositing and repair-region appearance still need visual review.
