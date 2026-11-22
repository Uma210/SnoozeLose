# SnoozeLose v1.7 — QA Report

**Release classification: SOURCE-LEVEL REPAIR CANDIDATE, NOT HARDWARE-VERIFIED / NOT APP STORE-READY.**

## Automated checks performed

- Swift source syntax parser on six `.swift` source files — PASS. This does NOT typecheck AlarmKit/SwiftUI frameworks.
- JavaScript `node --check` on parent controller plus all four pet inline scripts — PASS.
- Parent HTML and pet HTML duplicate ID checks — PASS.
- In-memory Chromium visual rendering at 320x568, 375x667, 390x844, 430x932 — PASS with no page JS errors. Screenshots are of in-memory web content, **not** WKWebView or Xcode simulator output.
- Parent action bridge in Chromium: Dance -> excited, Fish -> eating, Ball -> toying — PASS.
- Parent Pet Settings dialog and Help dialog: open/close; volume slider updates — PASS.
- ZIP CRC and referenced file checks — performed during final packaging; see accompanying test report if available.

## Gaps that still block a release

1. Full Xcode build/sign + iOS 26 AlarmKit compile/typecheck, as well as iOS 16–25 notification fallback.
2. Locked-phone system alarm: Stop, custom Solve Challenge action, recurring next-day schedule, snooze timer and app return.
3. Verify `stop(id:)` after successful challenge on a real iPhone; do not assume it cancels future occurrences.
4. Confirm permission request denial, no-alert saved state, denied -> Settings recovery, edit/disable/delete and scheduling races.
5. Overlapping live alarms, practice sessions while live, app background/relaunch, snooze cap and quick succession notifications.
6. Test real `WKWebView` geometry, modal/focus behavior, safe areas, 320pt width, Dynamic Type, VoiceOver and Reduce Motion.
7. Profile CPU/GPU/battery in Instruments, mic/audio lifetime, speaker echo and permissions, low power and memory pressure.
8. Validate reusable art licensing, App Privacy declarations and Android roadmap.
9. Integrate user's pending prebuilt games and run gameplay/scoring/daily content quality tests. This was intentionally excluded from v1.7.

## Native behavior caveats

- A standard notification fallback **does not equal** a persistent iOS system alarm.
- The system Stop action remains available; snoozing through the in-app action is not the same as pressing iOS system Stop.
- Foreground app effects can stop when the app backgrounds; that does not establish system alarm state. User-facing text distinguishes them.
- Scheduled system timers via AlarmKit are implemented at source level, but support details, permissions and exact behavior need a real iOS 26 test.
