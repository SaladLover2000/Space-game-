# Shared-space and damage-aware diorama

The pixel-art perspective viewer now uses the same SpaceBackdrop renderer, world-camera scenery, cruise_seconds clock and planet trajectories as the side views. The former separate sparse star screen was removed. The ship has slow, low-amplitude drift while scenery moves coherently. Panning affects the scenery camera as well as the ship presentation. Lights remain steady.

A registered damaged atlas adds cracked cockpit glass, opened central service covers, exposed wiring, loose aft panels and dim nozzles. Unpurchased cockpit, quarters and engine restorations select this state. Per-angle region overlays restore the purchased system; all three repairs select the completely clean atlas. Minor structural hull damage adds scuffs without turning repaired systems into mechanical faults. The free-orbit mesh mode also shows broken engine panels, exposed cabin services and a glazing fault until the corresponding restoration is owned.

The optional mesh SubViewport is transparent so it can use the shared space layer behind it. This configuration and camera/resource logic are tested headlessly; actual GPU compositing still needs a rendered review. The pixel diorama remains a directional eight-sprite viewer, separate from the free-orbit mesh inspector.

Original damaged artwork created with the built-in image tool:
- assets/art/ship-pixel-angles-damaged-v1.png
- exact prompt: docs/art-prompts/pixel-angle-damage-art-prompt.txt
- registered intact reference: assets/art/ship-pixel-angles-v2.png

The atlas itself was visually inspected. The game remained closed and all checks ran headlessly, as requested. New chat images show the asset, not a gameplay screenshot.