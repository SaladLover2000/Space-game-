# Runtime structure

This refactor preserves the existing artwork, game rules, save version, full study history and Game API. It does not claim new GPU or visible-window acceptance.

## State and services

`scripts/game.gd` owns shared state, focus timing/rewards and signals. Its public methods delegate to `scripts/services/`:

- `save_store.gd`: schema validation, migration, atomic save replacement, healthy backup preservation and decal ownership cleanup.
- `shop.gd`: parts, restoration, projects, decor, effect lookup and engine assemblies.
- `flight.gd`: travel, asteroid contacts, repairs and propulsion gates.
- `docking.gd`: station/planet contacts, fees, approach gates and departure.
- `robot_care.gd`: care, optics and contextual activity/thoughts.
- `customization.gd`: decals, callsigns and sensor hardpoints.
- `catalog_loader.gd`: startup JSON parsing and catalog validation with file/item diagnostics. Invalid core data stops gameplay with a readable error instead of continuing with partial catalogs.

`commit_or_rollback()` persists a change or restores its prior state. Settings go through `set_setting()`; failed toggles restore their visible value. Focus-task edits also go through Game; failed writes preserve the draft and prevent the Start callback from launching a session. Failed undocking returns false and leaves the player at the current port. Restoration purchases follow the same rollback contract.

`data/balance.json` supplies port fees and levels, station condition gates, quarters decor prices, hull patch cost/strength and robot care costs/strength. Existing engine repair prices remain authoritative. Pages and workshop/engine service labels use those values. `contact_geometry.gd` gives fly-by artwork and planetary availability the same named geometry constants.

## Page ownership and typing

`ui/main.gd` keeps navigation, shared focus controls and room interactions. `ui/pages/` contains a builder for every destination and a shared base. The base clears references to nodes owned by outgoing content automatically, so new page fields do not need a manual null-reset list. Shared controls outside content survive. Pending page fades are canceled during navigation.

Main/workshop/service-panel references use their concrete script types. Services have named classes and explicitly typed local boundaries. `OrbitSaveData` is a typed serialization boundary; the shared state remains a backward-compatible dictionary. A full typed field-by-field state migration is intentionally left for incremental work rather than changing the save representation in this refactor.

The original theme values now live in `ui/orbit_theme.tres`.

## Cost and save behavior

Parts are indexed by ID once. Equipment effects are cached against a copy of the current outfit, so purchases, free swaps, rollback and reload invalidate the result by value. Explicit preview outfits are computed independently. Contact labels update at four Hz and only change text when needed. The chime is constructed once.

Synchronous serialization uses a shallow snapshot instead of copying the entire history. Full history and previous-file validation remain intact: no records are capped or discarded. Large-save serialization, previous-file reading and validation are still linear in save size; this refactor does not claim constant-time saving or a measured frame-rate improvement.

Loaded decal paths must be canonical generated PNG paths inside `user://decals/`; unsafe paths are cleared while retaining the rest of the save. Cleanup removes only generated artwork unreferenced by both the current snapshot and its recovery backup. Failed imports remove the new file and retain the previous artwork. An old image can remain until the next successful save rotates its backup reference.

## Background validation

Run from the project root, substituting the installed Godot console executable:

```sh
python tests/run_checks.py --godot /path/to/godot --report results.json
```

The runner defaults to headless, defines suites once and creates fresh isolated APPDATA, LOCALAPPDATA and XDG directories for every invocation. Use `--save-root` to select their parent; the default is `work/test-runs`. Test saves remain available for inspection and `work/` is ignored by Git. Do not invoke graphical checks without explicit player permission.

Current result: headless editor import plus 499 assertions across 19 suites, with no GDScript compile/runtime errors. The added 48 checks exercise every page's outgoing ownership, persistent shared controls, settings callbacks and save rollback, undocking rollback, data-driven service prices, effects after reload, malformed catalog diagnostics, decal migration and backup-aware artwork cleanup. Invalid catalog fixtures deliberately emit contextual error messages. See `structure-check-results.json`.
