# Assets, Privacy & Platform Compliance — Release Gate

The ice-blue skyline is retained from the supplied reusable visual source. **Redistribution/commercial usage rights have not been independently verified.** Confirm license/ownership or replace with owned artwork before publishing.

Pebble's original SVG and animation are embedded locally in `pebble-pet.html`. This build includes no third-party CSS/JS CDNs and no external fonts. The active web UI loads a local skyline PNG and a local iframe pet renderer.

The microphone is requested after tapping Talk. The app has `NSMicrophoneUsageDescription`. The mic/repeat feature is subject to WKWebView permission/support and hardware verification. The HTML audio prototype is designed to process recordings locally; review actual code, network behavior, retention, user disclosures, and Apple's App Privacy questionnaire during release preparation. Do not claim certification without validation.

AlarmKit requires `NSAlarmKitUsageDescription` and user authorization. iOS 26+ supports prominent system alarms; iOS 16–25 uses standard notification fallback. iOS system Stop cannot be removed. Silent settings, haptics, and flashlight are not equivalent across background/system and in-app paths.

Before submission: build with supported Xcode, run accessibility checks, confirm app icon/provisioning, provide privacy policy and support information, verify trademark/artwork rights and platform entitlements, and conduct overnight alert regression on a locked physical phone.
