# Growing starship milestone

The starter ship retains its three upper-deck cabins. Build & research can add a research lab below the living quarters, a fabrication workshop alongside that lab, and a hydroponics habitat on a further lower level. These have predefined, connected construction sockets; this is not an unrestricted free-placement ship editor. The lab requires restored quarters and accumulated study XP. Construction spends credits once. Research XP is a milestone and is not consumed.

The lab offers navigation software rebuilding, deep-space sensor calibration and closed-loop life support. The first changes the immersive bridge's navigation state, the second enables a scanner in the optional mesh inspector, and life support unlocks the habitat. Existing saves default to no expansions/research and keep their prior purchases. New transactions roll back on save failure. The robot follows the central lift and connecting deck routes into purchased rooms.

The Bridge page uses a detailed cockpit scene with a larger live modular robot working at the diagnostic panel, navigation controls or resting. Its background glides subtly. Pixel diorama is the default presentation on the 3D page: eight separate original elevated pixel-art angles. It is a directional sprite viewer, not continuous mesh rotation. A separately labelled free-orbit mesh inspector remains available; the two views are deliberately distinguished.

Dragging the side view moves the world camera and its scenery, not the ship transform. In the perspective viewer, Shift + drag pans the camera, ordinary drag turns the view, and the wheel zooms. Fit resets the camera. Distant cloud shading is no longer tiled brightly; stars stream coherently and planets pass over cruise time.

Asteroid fly-bys occur about once per 100 seconds while the app is open. A quarter are contacts, and only six percent of those contacts plan damage. Damage is applied once at contact time, removes two hull points, never study rewards or credits, and cannot take integrity below 80. A hull patch costs five credits and restores ten points. When damaged, the robot makes slow free field repairs, one point per 30 seconds while open. Closed-app time produces no encounters or repairs. These are intentionally light ambient events, not combat or survival pressure.

Uncommanded robots cycle between maintenance, rest, sleeping, observing and the charging dock during focus. Manual room/seat commands take priority. Sleeping is rendered on the bunk; charging is cosmetic and does not grant battery outside completed study. The bridge robot is substantially larger than the prior version. Steady lamps and quiet UI are the default for motion comfort.

New original assets generated with the built-in image tool:
- assets/art/immersive-cockpit-v1.png
- assets/art/expansion-modules-v1.png
- assets/art/ship-pixel-angles-v2.png

Exact prompts are in docs/art-prompts/immersive-cockpit-art-prompt.txt, expansion-modules-art-prompt.txt and pixel-angles-art-prompt.txt. Generated files were visually inspected. No visible game was opened, so assembled layout, GPU appearance and comfort have not been visually accepted. Asset images shown in chat are not gameplay screenshots.
The final angle atlas uses the additional pixel-angles-padding-art-prompt.txt edit to isolate all eight views with clear transparent spacing. The earlier v1 atlas is retained locally as a generation draft; v2 is the active game asset.
