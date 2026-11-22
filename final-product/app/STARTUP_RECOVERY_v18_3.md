# SnoozeLose v1.8.3 — native-first startup recovery

## Scope
This revision does not change Pebble's animation, alarm scheduling, game rules, or assets. It removes the animated WKWebView as a prerequisite for the first visible app screen.

## Changes
- A native, functional loading screen is the FIRST rendered view. It contains Set an alarm and My alarms controls.
- Defer the memory- and CPU-heavy WKWebView creation until native SwiftUI has rendered.
- Defer schedule reconciliation until after native launch; no alarm rules changed.
- Keep a 10-second WebKit timeout and explicit Retry / My alarms fallback.
- Do not allow a hidden web view to intercept taps.
- Log native app-delegate startup, first SwiftUI frame, and WebKit home-file lookup in Xcode's debug console.

## Hardware verification required
We cannot execute or sign an iOS app in this environment, so this is a source fix, not confirmation of the user's specific launch failure. Test on the connected iPhone and share the first error in Xcode's debug console if it still exits, hangs on Launching, or fails before this loading screen.

## How to inspect a persistent failure
1. In Xcode, select your development Team, ensure the phone is unlocked and developer-mode/trust prompts are accepted.
2. Product > Clean Build Folder, then Run.
3. View > Debug Area > Activate Console. Look for `[SnoozeLose Startup]` or `[SnoozeLose WebKit]`.
4. If it exits or never leaves Launching, open Report Navigator and copy the device launch/crash error. A problem before `[SnoozeLose Startup] Native home appeared` cannot be caused by the home HTML; investigate deployment, signing, app launch, and Swift initialization first.
5. Check that `SnoozeLose/PebbleWorld` is a folder reference in Copy Bundle Resources.

## Notes
Swift syntax parsing and zip integrity are not a full Xcode compile. The root cause cannot be established without the device launch/crash log.
