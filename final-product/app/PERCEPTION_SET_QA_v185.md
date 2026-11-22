# Perception Set QA — v1.8.5

## Automated browser checks (Chromium, source HTML loaded in memory)

- 320 × 568: embedded game fills screen; no outer borders; Quick Count 53-dot deterministic test accepted with 100/100; no JS errors.
- 375 × 667: same pass; no JS errors.
- 390 × 844: complete game run twice — first intentionally failed (no native win event), then replay succeeded with 100 in Count, Track, Angle and Split. Exactly one native completion callback with `{won:true,average:100,scores:[100,100,100,100],rounds:4}`. No JS errors.
- 430 × 932: same compact-render and count interaction pass; no JS errors.
- Eliminated an embedded U+FEFF node from the source that introduced an unintended 18-pixel vertical offset.
- Game page has zero external scripts/assets/network imports.

## Static native checks

- All Swift source files pass `swiftc -frontend -parse` (syntax only).
- `.pbxproj` passes `plutil -lint`.
- Xcode folder reference `PerceptionSet` is present in resources build phase and contains `index.html`.
- JS scripts pass `node --check`; archive passes ZIP CRC.
- The existing model calls `model.complete(item)` only from onSuccess, and system ringer stops only after all required challenges have been solved.

## Not verified

- Apple SDK type-check / Xcode build, code signing and actual iPhone launch.
- iPhone WKWebView audio/keyboard focus/touch accuracy, VoiceOver, Dynamic Type.
- Locked-screen AlarmKit behavior, device flashlight, reentry from background, snooze race conditions.
- End-to-end native bridge on physical hardware; browser exercises the game + mocked bridge only.

**Do not rely on this prototype as a sole wake-up alarm.** Apple system Stop controls remain accessible.
