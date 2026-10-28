# Detailed pixel-art ship assets

Created with the built-in image generation tool on 2026-10-27. These are original generated game assets, not extracted sprites from the user's reference game. They replace the flat procedural base hull and cabin rendering; robot animation, equipment overlays, room hit-testing, mouse-wheel zoom, doors, warning animation and exhaust remain live game systems.

- `assets/art/ship-cutaway-restored-v1.png`: restored cabin atlas.
- `assets/art/ship-cutaway-damaged-v1.png`: matched damaged atlas with cracked glazing, torn bedding, broken lamp, disconnected piping and reactor faults.
- `assets/art/ship-exterior-v1.png`: matching closed exterior for Drift and workshop views.

All are transparent 1536x1024 PNGs. `assets/pixel_ship_art.gd` maps their deck to world y=103 and the two passage divisions to x=95 and x=172. Each purchased room selects its restored atlas region independently. The unpurchased rooms retain damage. The engine's red fault light blinks in code and vapor animates at the split pipe; white aft exhaust has been relocated to the raster nozzles. Palette tinting preserves interior theme selection. Existing component overlays and robot equipment remain equipped through the same save schema.

Exact prompts and edit invariants are saved in `docs/art-prompts/restored-pixel-art-prompt.txt`, `docs/art-prompts/damaged-pixel-art-prompt.txt` and `docs/art-prompts/exterior-pixel-art-prompt.txt`.

Visual inspection covered the generated asset files. No new running-game screenshot or graphical acceptance pass was performed because the user requested background-only testing. The asset previews in chat are not game screenshots. Existing screenshots in docs show previous artwork.