# Interactive ship rooms and propulsion

The existing Downloads/Space_game/SpaceStudy project is the working copy. No new ZIP or separate project was created.

## Explore and work

Returning players open directly on Ship. Home and Interior no longer duplicate its navigation. Click the cockpit to enter main control, or the engine room to enter propulsion maintenance. Exit returns to the cutaway. Closed connecting hatches continue to block the robot across room transitions; use Open connecting hatches to admit him.

The companion quarters use their own matching wall, charging cradle and electronics workbench, with no baked bed or books. The cradle opens charging; the locker opens robot customization. The bench has its own tinkering view. Restoring the quarters cleans the wall and removes loose spare parts. Restored quarters accept a terrarium, tool rack and relay project, bought once with credits.

Charging is a sleep presentation: optics off, head resting, rising z characters, orange chest/core indicator. At 100 percent battery the selected normal emitter color returns. Workshop optics colors are saved separately from hardware and panel paint. Battery remains earned through completed focus sessions; merely opening a room or leaving the application closed grants no rewards.

Robot arm and leg segments share anatomical endpoints. Profile/rear shapes use their own dimensions rather than centering every rectangle independently. Inspection uses a hip-centered upper-body lean, connected two-link leg bend, head tilt, separate shoulder/elbow/wrist movement and a held tool. Bridge navigation folds the legs and places the chair back in front of the seated lower body; hands work above the rim. Engine tasks walk between console, seals and spare parts; task buttons and stage clicks can request work. Thoughts cycle by room and condition rather than repeating one oil message.

## Propulsion and customization

Engine maintenance uses an empty mounting-room background with separately drawn turbopump, injector/chamber, cooling and nozzle sprites. Damage, repaired starter, reinforced and advanced art are separate atlas regions. Top-tier hardware adds visible bypass plumbing. Preview changes only displayed hardware; installing charges its catalog cost and changes the saved assembly. Damaged machinery produces occasional restrained sparks. Overhaul and affordable patches remain available.

Coast is the default. Powered cruise requires an overhauled engine, at least tier 1 pump/nozzle and sufficient engine condition. Maximum thrust requires all four assemblies at tier 3, full engine condition, thermal cladding and navigation software. Travel scenery and exhaust reflect the selected mode. These are fictional progression requirements, not a physical propulsion simulator.

External engine upgrades exclude the old nacelles from the hull draw geometry before inserting replacements. Fins continue to use the wingless hull layers. Cargo reinforcement has wider detailed ribs. Five additional full-hull paint finishes join the existing colors. Orbit/comet/constellation spray stencils, a callsign and locally imported PNG art are independent of hardware.

Sensors use fore, dorsal and aft hardpoints. Forward/dorsal LiDAR needs a clear approach sightline; rear LiDAR is rejected. Communications and radar can use the aft mount. The selected sensor type can be previewed, purchased and placed independently of other mounted instruments. Mounts appear in both cutaway/exterior and actual 3D geometry. Mounted approach hardware, rather than only the last selected catalog item, supplies docking clearance.

## Contacts and ports

Passing contacts have visible actions with prices and required levels. Station clearance costs 350 credits at ship level 3, with approach sensors, engine condition at least 75 percent and hull at least 90 percent. Planetary ports cost 500 credits at level 4 and require full hull/engine condition, thermal cladding, tier 2 cooling, navigation and approach sensors. Station approaches use volumetric modules and solar panels; planet approaches use textured spheres. Distant fly-bys remain sprites. Docking freezes travel and prevents propulsion engagement while focus time continues. Duplicate entry cannot charge twice; exit restores travel. Ports currently provide access to existing maintenance/customization services, not planetary exploration or trading.

## Art and engineering references

Built-in image generation created original matching components, modular room backplates and a corrected side-profile robot atlas. Exact prompts: [interactive-rooms-v1.json](art-prompts/interactive-rooms-v1.json). Asset registration is explicit in service_art.gd and engine_bay_art.gd. Pixel textures use nearest filtering; real 3D uses a reduced-resolution viewport and matte materials. Software previews compose actual textures and exported joint vertices; they are not captured game windows.

NASA's [propulsion overview](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/propulsion-system/) and [practical rocketry guide](https://www.grc.nasa.gov/WWW/k-12/rocket/TRCRocket/practical_rocketry.html) distinguish rocket-carried propellants from air-breathing jets. The pump impeller is fuel-system machinery, not a vacuum air intake. [Turbine engine components](https://www.grc.nasa.gov/WWW/K-12/BGP/turbparts.html) informed mechanical visual references. [Spacecraft guidance and navigation](https://www.nasa.gov/smallsat-institute/sst-soa/guidance-navigation-and-control/) informed star-tracker, LiDAR and rendezvous-radar roles. [Thermal protection systems](https://www.nasa.gov/reference/jsc-thermal-protection-systems/) concern atmospheric entry; the game's burn unlock also uses cladding as an explicit progression choice.

## Verification

All tests run headlessly with isolated APPDATA and LOCALAPPDATA under the workspace. test_immersive_progression.gd exercises mouse routing, hatch exclusion, focus continuity, actual emitter pixels, connected elbow/knee vertices, engine previews and installed sprites, cost gates and save rollback, sensor placement effects, station/planet entry fees, real 3D scene construction, room decor and disk reload. Existing suites cover focus rewards, doors, paint, hoist, 3D orbit and all 3,125 mixed robot builds. See interactive-rooms-check-results.json for the current runner result.

No visible game/editor window was opened for these checks. Headless assertions and software previews do not establish final GPU appearance, animation comfort, controller reach against every background pixel, or visible-window layout on the player's display. Those remain player review items.
