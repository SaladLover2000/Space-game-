# Cohesive art, articulated activities and replacement equipment

Robot front modules now use authored ivory ceramic PNGs, retaining dark mechanisms and cyan optics. No grayscale conversion or whole-image color tint is used for the assembled robot. Colored finishes use material-aware armor masks with colored side/cap panels, retained ivory center panels, edge wear, unpainted joints and optical elements. Paint remains independent of hardware. The same process paints hull armor across nose, center and aft sections while retaining glass, pipes and cutaway rooms.

Upgraded fins select new wingless exterior/restored/damaged hull sprites. Their top and lower replacement fins attach to the exposed roots; the lower fin is flipped vertically. Tight atlas regions exclude neighboring sprite fragments. The old single pasted paint panel is removed. Standard fins keep the original familiar ship artwork.

Hatches use matching industrial door frame/panel sprites with the original physical blocking and opening fraction. The maintenance display uses a pixel-art winch, chains and hooked spreader rather than a flat rectangular cage. Racking raises the robot eight world units; release lowers it. Installation still requires the completed service state and retains atomic purchases and rollback.

Robot action poses split arms into shoulder/upper-arm, elbow/forearm and wrist/hand sections. Maintenance cycles through reaching for a tool, using it and returning it. Side-facing work and walking poses expose joint motion. Selecting a control or engine room starts work when the robot reaches the equipment, without waiting for the idle hold to expire. Celebrations briefly interrupt chores and then return to the selected task.

Bridge navigation seats a larger rear-facing robot at the pilot controls with articulated typing hands. Diagnostics faces the service console; monitoring/rest remains seated. An unrepaired bridge uses a new damaged image with cracked screens, open panels, loose cables, debris and a ruptured fitting; the cockpit repair selects the restored image. The dedicated Drift tab/page is removed; shared cruise motion remains in normal ship views.

The true free-orbit 3D ship no longer repeats a photographic-looking hull crop on every surface. It uses a small authored pixel-panel texture, matte quantized-looking material colors, reduced-resolution nearest-filtered rendering and coordinated hull paint. It remains a real solid model and still differs in geometry from the illustrated side ship; it has not been replaced with flat angle sprites.

New built-in-image-tool assets in assets/art:
- robot-modules-white-v1.png and robot-modules-white-v2.png
- immersive-cockpit-damaged-v2.png
- maintenance-hardware-v1.png
- ship-core-exterior-v1.png, ship-core-restored-v1.png and ship-core-damaged-v1.png

Exact prompts are in art-prompts/robot_white-rebuild-prompt.txt (the second edit substitutes both rows for all three rows), bridge_faults-rebuild-prompt.txt, maintenance-rebuild-prompt.txt and wingless-hull-prompt.txt. Source geometry/dimensions were preserved and existing modular ownership is unchanged.

All validation runs are headless. tools/export_visual_preview.gd exports actual runtime textures, joint poses, lift layout and replacement fin recipes; tools/render_visual_preview.py makes software previews without opening a game window. These previews are explicitly not gameplay captures and do not validate GPU material appearance, window layout or input comfort. Player progress is never used as a test fixture.

Final verification: editor import plus 392 assertions across 17 suites passed. The new 22-check suite covers actual arm segmentation and tool attachments, tool pickup/use/return phases, manual task arrival, seated actor placement, bridge repair state, hoist elevation, multi-material paint, missing stock fin silhouettes, lower-fin orientation, full-hull paint coverage and Drift removal.

