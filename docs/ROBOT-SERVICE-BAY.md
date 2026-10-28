# Robot parts, independent finish, and maintenance lift

Hardware and color are independent. Twenty-five hardware designs now occupy five physical slots: heads, chassis, arms, legs and chest/backpack modules. Ten new Explorer and Loader designs add binocular/camera heads, barrel/heavy torsos, claws/hydraulic fists, spring legs/piston boots and scanner/reactor packs. All 3,125 mixed hardware builds use the same attachment system and retain real size differences.

The original atlas is desaturated at runtime, once per shared cached atlas, so old blue heads and orange legs become neutral shades before the warm white ceramic finish is applied. New artwork is already neutral. One independently saved robot_paint equipment slot applies the same finish to every selected module. Warm white ceramic is free and is the migration default; sand, cobalt, sage, crimson and brass finishes cost 20 credits each and can subsequently be swapped freely. Color does not replace geometry and changing geometry does not replace color. This first version provides coordinated whole-robot finishes rather than separate per-limb colors.

Open Robot, choose Rack robot in lift, and wait for the platform/clamps to finish their 1.2-second travel. Hardware and paint install buttons are disabled until racked, and the callback also checks that state. Previews remain available without spending. A successful installation has a short service cycle; another installation or release is blocked until it finishes. Release retracts the clamps. The lift is an in-game view, with no native popup. Entering/leaving the page does not grant rewards or stop focus time.

Purchases use existing atomic save/rollback behavior. Owned modules and paint remain free to reinstall. Older saves receive the neutral finish while retaining their purchased hardware. Old equipment IDs remain stable; former color-based display names now describe the shapes.

The original generated neutral sprite atlas is assets/art/robot-modules-v2.png. It was made with the built-in image tool; the exact prompt is in art-prompts/robot-modules-v2-prompt.txt. No external reference character was copied. Runtime palette normalization uses Godot Image.adjust_bcs: https://docs.godotengine.org/en/4.4/classes/class_image.html#class-image-method-adjust-bcs

Tests exercise all hardware combinations, actual neutral texture samples, previews versus purchases, timed rack/clamp state, actual install-button callbacks, in-progress blocking, paint/geometry independence, save reload, old-save migration and failure rollback. Visible GPU layout and animation comfort still require player review; all testing remained in the background.


The current component-only cards, workshop backdrop, four directional views and active equipment effects are documented in COMPONENT-WORKSHOP.md.

