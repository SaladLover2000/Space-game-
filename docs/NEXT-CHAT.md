# Fresh-chat handoff

Continue Little Orbit / Space Study, a Godot 4.4.1 GDScript study game. Read docs/INTERACTIVE-ROOMS.md and docs/VALIDATION.md before changing anything, then inspect the current code and the latest GitHub branch head.

## Working project and Git

- One active project: C:\Users\batgi\Downloads\Space_game\SpaceStudy
- Scratch/tests/runtime: C:\Users\batgi\Documents\Codex\2026-10-26\files-pasted-by-the-user-project\work
- Godot console: scratch\godot\Godot_v4.4.1-stable_win64_console.exe
- Python: C:\Users\batgi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe
- Private repository: https://github.com/SaladLover2000/Space-game-
- Development branch: dev/phase-1-prototype
- Existing PR: https://github.com/SaladLover2000/Space-game-/pull/1
- Do not merge the PR. Local working folder is not a Git checkout; GitHub connector blob/tree/commit/ref APIs have been used to publish. Verify branch head directly, use an expected-head lease and keep commits on the existing branch.

## User instructions that must persist

Keep ALL tests in the background. Never open, close, focus or launch a visible game/editor/test window without asking and receiving explicit permission. Use --headless; no --graphical. Do not disturb the user's current game. Every progress update and final answer must include an image. Distinguish software asset/pose previews from gameplay screenshots. Keep one working project, no new ZIP copies. If cleaning old files, move outdated material to Downloads\trash rather than deleting it or creating archives. Preserve player saves and study progress. Do not spawn subagents unless the user explicitly requests them.

## Current build

Ship is the consolidated main view. Cockpit and engine clicks enter immersive rooms, with closed hatches blocking the robot and exits returning to the cutaway. Companion quarters have a matching charging stand, electronics workbench and parts locker. The stand opens charging, not customization; the locker opens the robot workshop. Charging sleeps with dark optics, orange core and zzz; a full battery restores the independently selected normal light color. Battery remains earned by completed focus sessions.

The robot uses 25 interchangeable hardware designs across five slots, separate coordinated panel paint, four directional views, condition-dependent wear, care and an animated chain hoist for installation. Inspection bends connected hips/knees/elbows/wrists; visible soles stay on the floor. Bridge navigation uses a seated rear pose with chair occlusion, typing arms and a live navigation terminal. Room-specific thoughts cycle. Engine tasks walk between the console, seals and parts crates. Repaired quarters become clean and can gain decor.

Propulsion has actual modular pump/injector/cooling/nozzle artwork, preview and three purchased tiers. Installed upgrades change machinery. Coast/cruise/max-thrust have progression gates and change travel/exhaust. Exterior engines and fins replace their original draw layers. Hull reinforcement is visible; paint covers hull/components, with extra colors, spray stencils, callsigns and local PNG art. Sensors can occupy fore/dorsal/aft hardpoints with real approach effects and appear on the 3D model.

Space scenery drifts with planet/station fly-bys. Contact actions show prices and levels. Station clearance is 350 credits/level 3; planetary ports are 500/level 4 with condition, thermal, navigation and sensor gates. Approach views use actual 3D geometry. Docking freezes travel while focus continues. Ports currently open existing services, not planetary exploration/trading. No missed-day penalties or lost study rewards.

Focus requires a written task, uses monotonic elapsed time and grants rewards once. The timer is an in-game panel that can be hidden; shop/robot views hide it without pausing focus. Saves are versioned JSON with atomic replacement, backups and name autosave.

## Verification and remaining review

The strict background runner passes editor import plus 451 assertions across 18 suites, including 59 immersive-room/progression checks. See docs/interactive-rooms-check-results.json. tests/test_immersive_progression.gd verifies real mouse routing, optic/core pixels, joint geometry, floor contact, costs, preview vs purchase, save rollback, hardpoint effects, docking/landing fees, scene geometry and reload. Do not substitute script loading or assertions that merely mirror the implementation for behavioral tests.

Set APPDATA and LOCALAPPDATA to scratch\appdata and scratch\localappdata for every test. Run tests/run_checks.py with --godot pointing to the console executable and --report to scratch. Avoid running against the player's save directory. No visible game/editor was opened for this update.

docs/previews/interactive-rooms-software-preview.png is composed from actual textures and exported joint vertices, not a GPU screenshot. All final GPU appearance, animation comfort, interaction reach against artwork, and real desktop layout still need user review. The ship has a genuine free-orbit 3D model and a separate explicitly labeled illustrated-angle option. The robot is still an articulated 2D sprite rig with directional artwork, not a true 3D robot model. Preserve the detailed cream/white, navy, brass pixel-art direction; avoid generic smooth meshes, whole-image hue shifts, pasted upgrade duplicates and flashing outlines.

Generated art is copied into assets/art; exact built-in image-generation prompts and NASA propulsion/sensor/thermal references are recorded in docs/art-prompts/interactive-rooms-v1.json and docs/INTERACTIVE-ROOMS.md. Continue from this implementation and the user's next feedback; do not restart or regenerate the whole game.
