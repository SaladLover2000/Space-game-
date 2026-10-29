# Little Orbit / Space Study handoff

Godot 4.4.1 study game. Read [INTERACTIVE-ROOMS.md](INTERACTIVE-ROOMS.md), [VALIDATION.md](VALIDATION.md), and [STRUCTURE.md](STRUCTURE.md) before editing.

## Repository workflow

Continue on `dev/phase-1-prototype` in `SaladLover2000/Space-game-`. Existing PR: https://github.com/SaladLover2000/Space-game-/pull/1. Do not merge it. Inspect the live branch head before publishing and use an expected-head lease when updating the ref.

## Preserve behavior and player progress

Continue from the existing implementation and the player's next feedback. Keep one working project; do not create ZIP copies. Preserve saves, study history, rewards and their versioned JSON format. Keep the detailed cream-white, navy and brass pixel-art direction, interchangeable robot hardware, independent panel paint and optics, immersive rooms and visible installed upgrades.

All automated checks must run in the background with `--headless` and isolated test saves. Never open, close or focus visible game/editor windows without explicit permission. Include an image with every update and distinguish software previews from gameplay screenshots.

## Implementation and verification

The Ship view leads to the bridge, quarters, charging cradle and engine bay. Closed hatches block companion access. Charging grants no rewards; completed focus sessions supply battery. Propulsion, sensors and port access retain their progression gates. Ports expose existing services, not exploration or trading. The ship has a real 3D viewer; the robot remains an articulated 2D sprite rig.

Game owns state/signals and delegates domain operations to services. Pages use a shared lifetime/teardown base. Prices come from balance data. See STRUCTURE.md for boundaries and testing instructions.

Software previews in `docs/previews/` compose real assets and pose data. They are not gameplay screenshots. Final GPU appearance, animation comfort and desktop layout still require player review.
