# SnoozeLose v1.8.0 (build 19) — Launch recovery and challenge alarms

## Updated files
- `SnoozeLose/PebbleWorldView.swift`: native branded loading screen with the actual expressive Pebble illustration, 10-second WebKit timeout, file-resource checks, DOM validation, WebKit process failure detection, Retry, and native alarm controls when the animated home cannot load. A failure does not leave the user staring at a blank page.
- `SnoozeLose/Assets.xcassets/PebbleLoading.imageset`: static transparent loading artwork extracted directly from the user's Pebble v17 expressive SVG.
- `SnoozeLose/SnoozeModel.swift`: keep the unsolved wake session persistent and resume foreground ringtone/LED/haptics on returning to the active app; stop effects immediately after the last required game is solved; default flashlight pulses to enabled for newly created alarms (existing saved alarms retain their settings).
- `SnoozeLose/WakeRinger.swift`: loop audio in the foreground, add cancellable/generation-checked torch pulses, use a low torch level (0.20), and always turn the torch off on stop/backgrounding.
- `SnoozeLose/SnoozeDashboard.swift`: clarify safe emergency silencing, foreground-only torch controls, user-visible platform constraints, and updated version string.
- `SnoozeLose/PebbleWorld/js/home.js`: fix the disabled fog animation frame scheduling and show iframe load-error feedback.
- `SnoozeLose.xcodeproj/project.pbxproj`: version 1.8.0, build 19.

## Original behaviors retained
- The expressive Pebble SVG, pet reaction commands and side rails.
- Alarm editor and scheduled alarms, snoozing and challenge count cap.
- All current game source (`ChallengePlayer.swift`) is byte-for-byte unchanged, awaiting the user's game package.
- iOS system alarm scheduling with AlarmKit, and notification fallback for older iOS versions.

## Platform boundaries — important
- **No iOS app can disable the system Stop control, prevent the Home gesture, or make its challenge an unescapable system-wide lock.** The in-app full-screen challenge remains open until solved, but users may leave the app or silence the system alert.
- AlarmKit, when permitted on iOS 26+, is the system-managed lock-screen alarm. A notification fallback on iOS 16–25 is **not** a continuous alarm.
- Local AVAudioPlayer looping audio, custom vibration, and flashlight pulses run **only while SnoozeLose is foregrounded**. iOS may stop the torch and app audio when the app leaves the foreground. The user controls phone output volume.
- The flashlight emits restrained brief pulses, not an unlimited continuous high-power beam, for comfort and heat safety. It can be turned off in each alarm's editor. It is ON by default for newly created alarms in v1.8.
- On iOS 26+, a system AlarmKit alert may overlap the foreground playback when launching from the alarm. Test the resulting audio levels on hardware before release.
- Emergency silence stops local audio/torch without falsely marking the session completed. Background/foreground transitions rearm in-app effects for unfinished live sessions. Device emergency controls remain available.

## Checks run
- Swift front-end parsing for all files (syntax check only; not an iOS SDK build).
- Xcode project plist syntax validation.
- Inline and external JavaScript syntax checks; resource existence and duplicate ID inspection.
- Chromium in-memory rendering at 320×568, 375×667, 390×844 and 430×932, including Pebble iframe, dance, food, modal actions and no JavaScript errors.
- ZIP CRC verification and a byte-for-byte equality check on unchanged game code.

## Real-device acceptance tests before relying on this as an alarm
1. In Xcode select the SnoozeLose target, your Apple Team, and automatic signing. Clean Build Folder and run on your iPhone.
2. Launch with a working bundle: branded loading screen must transition into the complete home. Temporarily remove the PebbleWorld bundle folder in a local test build: loading should switch to an error screen with Retry, My alarms, and Set alarm.
3. Use alarm editor, authorize AlarmKit (iOS 26+) or notifications (iOS 16–25), and confirm the alarm status is Armed; permission denial must show Not armed.
4. Set an alarm one or two minutes ahead. Lock the phone; confirm the real scheduled OS alert appears, then open Solve Challenge. Start and observe foreground looping sound and controlled LED pulses, if the hardware supports torch.
5. Leave the app before completing the challenge: confirm the torch goes OFF; return: the same unsolved challenge and foreground effects should resume. System alarm sound, if any, remains controlled by iOS.
6. Solve every assigned challenge: audio and flashlight should stop immediately; the completion page remains until Dismiss alarm.
7. Exercise Snooze and 0–5+ attempts, including interrupted games, overlapping alarms, and permission changes.
8. Test an actual iPhone in silent mode, Focus, locked/unlocked, low-power mode, no torch, VoiceOver, Reduce Motion, and after app relaunch. Use a backup alarm until all hardware tests pass.

## Not verified
This environment has no macOS Xcode/iPhone simulator or physical iPhone. A successful device build, audio routing, AlarmKit lifecycle, flashlight operation and store submission are **not** claimed.
