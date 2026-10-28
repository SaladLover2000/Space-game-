# Component shop and upgrade effects

The existing split shop remains: assembled preview on the left and independently scrolling cards on the right. Robot categories now have direct Heads, Chassis, Arms, Legs, Packs and Paint tabs. Cards show only the selected component or limb pair. Preview assembles that module onto the current robot without spending or changing saved equipment. Ship cards use detailed actual engine, fin and marker-lamp artwork shared with their installed overlays.

The default robot finish is warm white ceramic with dark joints. Low battery no longer darkens the entire paint color. Existing colored parts are normalized and brightened before the independent finish is applied. Other finishes remain separate from hardware and persist as before.

Robot preview is set inside an original pixel-art workshop, retaining the rack/clamp/install/release lift. Front/right/back/left controls and horizontal dragging turn between four directional pixel-art views. All 25 modules have separate side and rear artwork; the opposite side reflects the symmetric profile. This is a directional pixel-art turntable, not a free-orbit 3D robot. Rear packs render in front of the rear torso so installed modules remain visible.

Hardware now has active effects listed under its description, a stat marker, a before/after build value and a small static meter. Current effects are research XP on completed focus, study battery recharge, walking speed, free hull repair rate, cruise scenery speed, rare-impact protection and head-mounted maintenance light cones. Pure appearance items say so explicitly. No future repair missions are advertised as already implemented.

Research bonuses cap at 15 percent; combined free repair rate bonuses cap at 60 percent. Hull armor reduces a rare two-point contact to one point. Walking, repair intervals and cruise clock consume their actual equipped effects. Research and battery bonuses are captured when focus starts, rounded down at completion and recorded with the once-only session reward; swapping during a session cannot change that session's bonus. The focus dock shows the adjusted reward. Credits remain unchanged. Missing effects in older saved sessions mean baseline rewards.

Images were created with the built-in image tool and copied into assets/art: robot-modules-side-v1.png, robot-modules-back-v1.png, robot-workshop-v1.png and ship-components-v1.png. Exact prompts are in art-prompts/robot_side-v1-prompt.txt, robot_back-v1-prompt.txt, robot_workshop-v1-prompt.txt and ship_components-v1-prompt.txt. Actual source dimensions and alpha regions, rather than requested generation dimensions, determine atlas calibration.

Background tests verify isolated component cards, direct tab callbacks, real profile/rear source regions, assembled selected modules, drag controls, previews without spending, installed engine regions, contained marker fixtures, actual movement/repair/impact/cruise behavior, snapshotted focus rewards, recharge bonuses and save reload. Assembled GPU appearance and input comfort still need player review. No visible game window was opened.

