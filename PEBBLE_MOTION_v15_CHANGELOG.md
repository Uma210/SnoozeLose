# SnoozeLose v1.5 — Fluid Pebble Motion

## Scope and approach
This revision is a **character-rig / animation-engine update** to the existing SnoozeLose v1.4 Xcode project. It does **not** alter alarm scheduling, snooze counts, challenge scoring, alarm sounds, or game rules. Pebble remains within the home-screen WKWebView. No network service, dependency, or external image asset was added.

## Changes made in the real source
- Rebuilt Pebble's SVG from a visually rigid body into a layered torso and **separate head joint**. Eyes, eyelids, eyebrows, cheeks and *all mouth variants* now travel with the head, preventing floating facial features.
- Moved invisible head and belly hit regions into their corresponding movable SVG groups, keeping gestures registered during head/body motion.
- Grouped the eye pupils with their highlights so eye tracking does not dislocate the highlights.
- Increased the SVG viewBox safety margin (`-24 -13 252 268`) for expressive wing movement without cropping.
- Replaced rigid repetitive whole-body CSS animation loops with a **single requestAnimationFrame pose controller**: spring-damped torso shift, head tilt and gaze, independently animated flippers, alternating foot steps, breathing squash/stretch, and bounded toy/fish object movement.
- Mapped 16 existing character moods (idle, listening, talking, happy, laughing, excited, surprised, angry, dizzy, shy, smug, yawning, sleeping, eating, toying, playing) into distinct animated pose targets. Transitions blend instead of hard-resetting the whole character.
- Attached transient interaction impulses to existing reactions. Dragging causes bounded, gentle lean; finger movement drives eyes and head.
- Preserved the original microphone, record/repeat, voice lines, feeding, toy, speech, settings and mute handlers. Motion is entirely separate from Swift and the native alarm bridge.
- Removed the legacy competing random-blink routine; the fluid motion controller now owns blink cadence, and the old idle branch shows a brief smug expression instead of doing nothing.
- Replaced the animated movement selectors in CSS with an explicit, documented override while keeping their expression visibility rules.
- Stops animation when the document is hidden, honors **prefers-reduced-motion**, and detaches its own pointer and visibility listeners on disposal.
- **No visible Pause Motion button** was added.

## Why this instead of 'more bouncing'
More dramatic whole-character keyframes would reproduce the original rigid look and create clipping. This iteration distributes motion into the head, wings, feet, pupils, belly and props. The body moves only a few SVG units while the extremities move more, conveying weight and intent. Spring damping reduces sudden jumps when actions change quickly.

## How to adjust character movement
Search for `PEBBLE FLUID MOTION ENGINE v1.5` inside `SnoozeLose/PebbleWorld/pebble-pet.html`.
- `preset`: base pose for each state; adjust head, wings and body values.
- `stiffness` / `damping` in `move()`: transition responsiveness and softness.
- `energy`, `stepAmount`, `bounce`, `headRot`: expressive motion amplitudes.
- `pivots`: SVG joint origin coordinates; change only if modifying the art.
The animation is already embedded in `pebble-pet.html` to preserve the Xcode folder resource setup.

## Feature-selection trade-offs
1. **More movement vs alarm clarity:** more articulated motion on Pebble; no animation-driven changes to alarm buttons or game progression.
2. **High energy vs accessibility:** energetic reaction poses remain, while system Reduce Motion suppresses the continuous engine and decorative keyframes.
3. **Expressiveness vs clipping:** expand the vector canvas while bounding angles, instead of simply translating the entire penguin.
4. **More animation code vs reliability:** one animation loop, joint states and cleanup, rather than unrelated timers on each part.

## Publish/release gate — not yet cleared
Static SVG rendering and JS/Swift parsing are not a substitute for a compiled iPhone build or a real WKWebView visual test. In this environment managed Chromium policies block local file and localhost navigation, so the final visual integration could not be browser-certified. Before publishing: run Xcode build/signing; test on short/large iPhones at Dynamic Type and Reduce Motion settings; exercise every tap, drag, feeding, toy, speech and microphone permission state; validate alarm delivery, snooze escalation, challenge dismissal, notification handling, vibration, audio session interruptions, and background/foreground lifecycle. App Store review and privacy disclosures remain separate requirements.
