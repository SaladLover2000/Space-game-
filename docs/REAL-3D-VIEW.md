# Real 3D view and attached decks

The 3D tab now opens actual solid geometry with a continuously orbiting Camera3D. Illustrated angles remain explicitly labelled 2D. The former mesh inspector was a simpler separate model, which explains the visual mismatch reported by the player.

The rebuilt hull tapers in height and width through octagonal sections. Real canopy faces and framing, swept wings, engine collars, armor layers, vents, conduits and service hardware provide depth. A nearest-filtered metal texture samples the approved exterior pixel artwork and uses mesh UV coordinates. This is not an automatic conversion of every hand-painted detail into geometry; the true 3D model still differs from the illustration.

Dragging or zooming changes the ship camera only. The distant sky has fixed screen framing in both the side and 3D views; stars and planets still move with the shared cruise clock. The obsolete camera-relative 3D star spheres were removed.

Added decks have enclosed foreground lift passages, docking collars and lab support struts in side view. These draw after the main ship bitmap so its transparent margins cannot hide the shaft. Real 3D connector meshes overlap their neighboring rooms and hull. Robot travel routes and room bounds stay consistent with the existing lift.

Validation: the full background regression pass passed 325 assertions; the final texture and UV changes passed the expanded 27-assertion viewer suite (327 current assertions across the 14 suites). No visible game window was opened. GPU compositing, material appearance and motion comfort still require player review.

The software geometry preview is exported from the actual Godot meshes by tools/export_model_preview.gd. It omits in-game textures and lighting and is not a gameplay screenshot.

