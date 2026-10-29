# Modular robot artwork and assembly

The robot now uses the same detailed raster pixel-art treatment as the ship. Original modules were generated with the built-in image tool on 2026-10-27 and saved, unchanged, to `assets/art/robot-modules-v1.png`. Exact prompt: `docs/art-prompts/robot-modules-art-prompt.txt`.

The atlas contains fifteen designs and twenty-one separated physical pieces: three heads, three chassis, three arm pairs, three leg pairs and three equipment modules. `data/robot_atlas.json` stores tightly measured component bounds. The PNG was not cropped or painted by the asset pipeline; the renderer samples its individual regions directly.

The existing `robot_shell`, `robot_visor`, `robot_arms`, `robot_legs` and `robot_core` save slots and IDs remain compatible. Their shop labels now read Chassis, Heads, Arms, Legs and Chest & packs. Old purchases automatically receive the new component artwork and shapes. Prices and research gates are unchanged.

`assets/robot_art.gd` composes separate parts around the current hips, shoulders and neck. Each component keeps its source aspect ratio. Taller legs raise the existing torso/head; a broader chassis moves existing arms outwards; equipment behind the shoulders is a distinct layer. The compact service build, broad salvage build and tall survey build can be mixed in all 243 combinations. The shop reports each build's relative height and width. Portraits use a shared scale so taller parts actually look taller. The ship and status portrait use the same assembly.

Walking shifts legs and swings arms. A celebration raises an arm; charging adds a small live effect. These are code-driven poses, not baked whole-robot replacements. Closed hatch clearance derives from the equipped body's visible bounds. Purchases remain cosmetic progression and do not change study rewards.

Generated atlas files have been visually inspected. The assembled game has not been opened for graphical acceptance or a new screenshot; the user requested background-only testing. The atlas shown in chat is an asset preview, not a game screenshot.