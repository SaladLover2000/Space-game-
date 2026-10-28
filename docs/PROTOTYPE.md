# Little Orbit - Space Study

## Run the one active project

Double-click PLAY-GAME.cmd in this folder to launch the installed Godot 4.4.1 in a standalone window. Close an old run before reopening after a code update. The project remains in Downloads/Space_game/SpaceStudy; no additional ZIP or duplicate project is needed. Import project.godot in Godot if editing manually.

## Focus and navigation

Write what you are working on before starting. Blank/whitespace titles are rejected by Game as well as the UI. The compact bottom dock contains the task, countdown, duration presets and one primary Start/Pause/Resume action. Hide puts the dock away; Focus bar restores it. Shop and Robot modes hide it automatically while the same session continues. Names autosave in setup/settings. Study history stores the task with each completed session.

Ship and Interior show the live cutaway. Hold left mouse and drag to move the world camera and background; wheel zooms; Fit ship resets pan and zoom. A click activates on release after ruling out a drag. Click the pilot chair to walk over and sit. Open closed hatches on the route. Stand up or select another room to leave. Camera gestures do not move the ship or grant rewards.

Bridge is an immersive control-room scene with a larger live modular robot running diagnostics, working on navigation or resting. The 3D tab defaults to eight elevated pixel-art angle sprites; it is a directional art viewer, not continuous mesh rotation. Free-orbit mesh inspector is a separate mode. Drag turns, Shift + drag pans and the wheel zooms. Rendering/GPU appearance still needs visual review.

Shop is a game-style split view: a fixed ship/robot preview beside an independently scrolling upgrade panel. Robot directly opens the robot version of this shop. There are 21 ship designs and 15 robot designs across 12 slots. Preview never charges or grants ownership; purchases equip once, and owned parts swap freely. Robot parts compose 243 genuinely different mixed builds, with shared portrait scale and size-aware hatch clearance.

## Growing the starship

Build & research adds connected lower decks at predefined sockets. The lab is beneath the living cabin, fabrication extends alongside it, and hydroponics adds a deeper level. These are not freely draggable rooms. The robot follows the central lift and connecting deck routes.

Research milestones unlock navigation software rebuilding, a deep-space scanner and closed-loop life support. Projects spend credits once; accumulated research XP is a gate and is not consumed. Navigation research changes the bridge work state, the scanner appears in the mesh inspector, and life support enables the habitat. See data/expansions.json and data/research.json for prices/prerequisites.

## Economy and ambient flight

Completed focus earns 2 credits, 1 research XP and 1% battery per minute (battery capped at 100%). Pause/cancel grant no reward and never drain battery. Starter room restoration costs 40 credits for quarters, 50 for the engine and 60 for the cockpit. Engine patches cost 10 for 25 condition; full overhaul unlocks replacement engines. Workshop purchases and construction/research roll back on save failure.

Cruise scenery uses a dark distant cloud field, coherent star motion, passing planets and occasional asteroids. Encounters occur about every 100 open-app seconds. A quarter are contacts; only six percent of contacts cause two hull points of damage, applied once at contact time. Integrity cannot fall below 80. Study rewards and credits are unaffected. A 5-credit hull patch restores 10 points; automatic field repairs recover one point per 30 open-app seconds while damaged. Closed-app time produces no flight, damage or free repairs.

Uncommanded robots maintain systems, observe space, sleep in the bunk, rest or charge during focus. Manual room/seat commands take priority. Charging remains cosmetic outside study completion. Steady instrument lights are the default, with the setting available in Settings. There are no animated selection borders or rapid diagnostic-bar effects.

## Saves

Version-1 JSON saves are compatible with previous builds. Optional expansion, research, task, hull and cruise fields receive defaults on old saves. Purchases/names/history/session checkpoints use the existing local atomic temporary-file and backup scheme. Closing resumes a saved active checkpoint paused on the next launch. Closed-app time earns nothing. Existing unlabeled paused checkpoints need a task before resume.

## Verification and visual review

Run background checks with:

python tests/run_checks.py --godot C:/Tools/Godot.exe --report results.json

All suites use isolated save filenames. They exercise actual Game logic, signals, input callbacks, transaction persistence, atlas state selection, mixed robot geometry, seat routes, expansion lifts, camera movement, task gating, rare-contact handling and autonomous activities. They do not simulate the OS mouse or prove visual comfort. Current results are in docs/expedition-check-results.json and VALIDATION.md.

Do not launch the game or use --graphical without the user's explicit permission. No visible game launch was performed for this milestone. Asset images were inspected; the assembled UI, GPU output and comfort remain for user review. Historical screenshots in docs show earlier versions.

More details: GROWING-STARSHIP.md, UI-REFERENCES.md, MODULAR-ROBOT.md, PIXEL-ART-ASSETS.md and SEAT-AND-CAMERA.md. Exact built-in image-tool prompts are saved in art-prompts.

## Later work

Unrestricted ship building, collectible discoveries, a solar-system editor, combat, online features, wishlist/achievements and a packaged Windows executable remain future work. The current game is run through Godot. Exporting requires matching Godot export templates.

The perspective viewer now shares the side view's drifting space renderer and saved repair state. Unrepaired parts show the damaged angle atlas; purchased repairs restore their regions. See DIORAMA-SPACE-DAMAGE.md for the artwork, source prompt and review limits.


The 3D tab now defaults to a real continuously orbiting solid ship with UV-mapped pixel-art metal, tapered canopy, machinery and attached lower decks. The sky framing stays independent of pan/zoom. See REAL-3D-VIEW.md for current behavior and visual-review limits.


Latest robot service update: 25 hardware designs, 3,125 mixed builds, six independent whole-robot finishes, and a timed rack/install/release maintenance lift. Full background runner: 344 assertions across 15 suites plus editor import, with no script errors. See ROBOT-SERVICE-BAY.md and robot-service-check-results.json. No visible game window was opened.


Latest component workshop update: warm white base armor with no low-battery paint dimming; isolated component cards and direct robot slot tabs; four directional robot views with separate profile/rear artwork; pixel-art workshop and detailed installed engines/fins/contained marker fixtures; real equipment effects with snapshotted focus rewards. Final background runner passed editor import plus 369 assertions across 16 suites, without script errors. See COMPONENT-WORKSHOP.md and component-workshop-check-results.json. No visible game window was opened.

