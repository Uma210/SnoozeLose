# SnoozeLose v1.5 — Three-Pass QA Report

**Result:** Source-integrated candidate; **not verified publishable**. Confirmed software and structural tests are listed below. Hardware and platform tests are blockers, not hidden failures or success claims.

## Pass 1 — Source architecture and compilation/syntax
- `node --check` passes for all inline HTML scripts and all `PebbleWorld/js/*.js` project scripts.
- `swiftc -frontend -parse` passes for all Swift files (syntax only; does not link Apple iOS frameworks).
- No duplicate SVG IDs; every expression layer (mouths/eyes) and head hit zone belongs to the moving head group.
- Kept the native `SnoozeModel.swift`, `WakeRinger.swift`, `ChallengePlayer.swift` and other Swift files byte-identical to v1.4. The Xcode project still copies `PebbleWorld` as a folder resource.
- No new third-party dependencies.

## Pass 2 — Motion logic and visual geometry
- Executed a deterministic Node test harness against the exact shipped JS animation engine: 16 mood transitions, frame-by-frame finite transform output, finger tracking, dragging, reduced-motion stop/resume, document hide/show, and disposal. Passed.
- Renders of extracted actual SVG show coherent head/torso shapes in idle, excited, sleeping and dizzy poses. This is SVG geometry verification, **not** a full browser render.
- Confirmed there are not two animation loops scheduled by the new motion engine.
- In QA, a handler declaration-order runtime error was detected and corrected before release packaging. Re-test passed.

## Pass 3 — Integration and artifact consistency
- Preserved all native alarm/game source files and existing audio/icon resources.
- Rechecked inline JavaScript syntax after final edits; checked Xcode bundle resource paths and all local HTML `src`/`href` dependencies.
- ZIP archive integrity checked; main `.xcodeproj` is present with complete source.

## Release blockers (must be tested on hardware)
- Full Xcode build, code signing, launch/rotation and layout on supported iPhone devices.
- Real WKWebView animations at 60fps, including wing extents at every active state and any clipping under the app's safe-area insets.
- Microphone permissions/MediaRecorder/WebAudio on iOS, especially in bundled `file://` web views.
- Speech synthesis choice, mute and interruption behavior; audio-session conflicts with alarm playback.
- Scheduled alarm trigger when locked, backgrounded, or the app is terminated; system dismissal versus game dismissal constraints.
- VoiceOver, Dynamic Type, Reduced Motion, increased contrast, and touch targets on real hardware.
- App Store Connect privacy policy, metadata, screenshots, access permissions, and final review compliance.

## Recommended launch checklist
1. Open `SnoozeLose.xcodeproj` in a supported Xcode release and use your development team signing.
2. Compile for a physical iPhone and simulator; resolve build errors before distribution.
3. Open Pebble home and switch quickly among Wave, Dance, Food, Toy, Talk, head tap and belly pet. Verify face, wing, feet, fish and toy remain attached and visible.
4. Repeat on a short screen and with Reduce Motion ON.
5. Validate voice and microphone permission prompts on real hardware, including denial and interruption.
6. Verify alarm scheduling, background delivery, snooze escalation, and challenge-dismissal requirements independently of the mascot.
7. Run Instruments to assess energy impact and dropped frames, then complete App Store review checks.
