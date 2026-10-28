# Pilot seat and camera drag controls

Hold the left mouse button on the ship view and drag to pan horizontally or vertically. Mouse-wheel zoom preserves the current camera center. Fit ship resets both zoom and pan. This works in the interior, exterior and ship workshop views. Camera motion changes no robot destination, room selection, door state, credits or study time.

A click activates only after mouse release, once a six-pixel drag threshold has been ruled out. Dragging from a room, equipment fixture, hatch or workshop component cannot trigger its click action. Releasing outside the canvas, losing the held-button state, or losing window focus ends the gesture. This uses Godot GUI mouse capture, not OS-level mouse automation.

Click the pilot chair directly, choose the Pilot seat equipment entry, or use Sit in pilot seat in the cockpit inspector. The robot walks to the chair and waits at closed hatches. It sits only on arrival. The seated pose splits each equipped leg into thigh and shin regions, bends the knees toward the console and brings the arms forward. Every leg style aligns the body's hip connector with the same cushion height.

Use Stand up, click the chair again, or select another room to leave the seat. Pending seating can be canceled before arrival. A description refresh does not reseat or stand up the robot. Seating is transient presentation/movement state; it does not modify study rewards, battery or saved ownership.

The cockpit seat and navigation-console hit regions were recalibrated to match the current raster ship artwork. No visible game launch or screenshot was performed; testing remains headless at the user's request.