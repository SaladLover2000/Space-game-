# Room and robot visual/action fixes

The cream/white, navy and brass direction, existing balance rules, save version and saved progress are preserved. There are no new persistent fields and no changes to prices, rewards, upgrade effects, progression or focus timing.

## Changes

- Removed the repeating diagonal dither in the generated sky texture, which produced the sticky scanline effect when enlarged through the bridge window. No change to the saved calm-lights option is required.
- Moved Optics into its own correctly sized row, away from the part-tab grid and build-description text. Failed optics saves restore the selection.
- Bridge windows now show clipped moving stars and planets even at departure. Typing uses connected shoulder/elbow/wrist targets at a physical keyboard, with hands above the foreground chair back.
- The loose workshop hardware thumbnails now sit in a bolted rack. Engine components have suspension chains, mounting shelves and support legs rather than floating on the backplate.
- Corrected profile head artwork matches the five front designs. Only the new head crops are used; original body, limb and backpack art is retained.
- Walking overrides the task crouch and uses connected hip/knee/ankle chains, an alternating stance/swing phase and flat planted soles across all five leg designs.
- Charging uses a uniform actor scale and the actual cradle platform height. The neck/head no longer rotates away from the torso. Sleeping optics and their bright catchlights go dark, while the orange charging core and normal selected light behavior remain intact. Rising letters, the workbench flicker and charging thought popups are absent.
- Panel inspection reaches toward the visible screen without a wrench. Pump-seal work uses a held, pixel-drawn open-ended spanner with a torque motion at a fitting. Parts sorting picks up six real scene pieces, carries them with the hand and places them into rack bins; the arrangement visibly changes.
- Photo-like loose-spares overlays are replaced with small pixel gears, couplings and trays. The engine-room backplate has a cleared deck so baked loose parts cannot show underneath the interactive props.
- External engine replacement hides the complete old collar/rim area and attaches the new pods with continuous bolted coupling mounts. The interior connecting duct is a shaded flanged pipe rather than a crop of an obsolete starter component.
- Hull upgrades use eight segmented plates aligned to the actual hull surface, with bolts, edge seams and metal detail sampled in place from the existing hull artwork. They do not paste tall rectangular strips over the cabin or float above the outline.

## Engine assembly

After a successful module upgrade, the new module appears in the tray and the other three installed assemblies remain secured. Click or drag the new module into its matching socket. The free **Assemble installed engine parts** button lets the player rebuild the full four-part arrangement. Wrong sockets and duplicate placements do nothing. Return to maintenance exits the bench.

This is optional hands-on staging: the existing purchase already installs the saved tier, and assembly neither delays its effects nor adds costs, resources, rewards or progression gates. Staging is transient and introduces no save fields.

## Artwork and verification

Two new raster assets were required: design-matched profile heads and the engine-bay backplate without baked loose spares. Both were produced with the built-in imagegen tool and integrated into the project. Exact prompts and references are in `art-prompts/visual-actions-v1.json`. The wrench, small parts, supports, racks, keyboard and armor geometry are code-drawn using the existing palette/material textures. No additional artwork is required to run these changes; further hand-painted refinement of silhouettes and props is an optional art pass.

The strict runner passed headless editor import and **550 assertions across 20 suites**, including 51 focused visual/action checks. Coverage includes the sky's actual pixel pattern, all five leg chains and planted soles, charging stability, optics layout, window clipping, typing above chair occlusion, actual console reach, sorting transfers, real assembly mouse drops, upgrade-to-bench routing, unchanged state/economy and hull-material attachment. Tests use isolated saves. No visible game/editor window was opened or closed.

`previews/visual-actions-software-preview.png` is a software composition of actual textures and exported pose/window/engine/armor geometry. It is **not a gameplay screenshot**. The simplified software renderer does not establish final GPU lighting, animation comfort, physical desktop input or pixel-perfect UI acceptance. Those still need player review in a normal game session.

Run background checks with `python tests/run_checks.py --godot /path/to/godot --report results.json`. The new export/render tools accept a scratch output directory and do not launch a visible window. Existing game instances may need a player-initiated restart to load changed scripts and textures; the agent did not restart them.
