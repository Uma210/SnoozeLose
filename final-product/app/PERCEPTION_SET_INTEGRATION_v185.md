# SnoozeLose v1.8.5 — Perception Set integrated

## User-supplied game (mechanics preserved)
- Four stages, ordered: Count, Track, Angle, Split.
- Count: 5-second timer, dot estimate, -3 per dot off.
- Track: first third of projectile flight shown, tap projected landing, -5 per percentage-point error.
- Angle: drag ray for specified clockwise/counter-clockwise rotation, -3 per degree off.
- Split: tap fraction/percentage point from left or right, -1 per percentage-point error.
- Final: four per-round scores 0–100, `Math.round(average) >= 70` wins.
- Failed set offers Play again and DOES NOT notify native.

## Source changes
1. `SnoozeLose/PerceptionSet/index.html` — real supplied HTML plus embedded-layout styles and a win-only callback. No game mechanics, scoring, or target generation changed.
2. `SnoozeLose/PerceptionSetGame.swift` — complete native WebView host, full-screen game page, tokenized bridge, strict result validation, Retry.
3. `SnoozeLose/SnoozeDashboard.swift` — route active perception challenge to full-screen page rather than nested 450pt WebView. Other challenge UI unchanged.
4. Xcode version bumped to 1.8.5 (build 22). Existing PerceptionSet folder reference already includes the new index.html.

## Important behavior
- New live or practice sessions start with this game because `PerceptionSetBundle.isAvailable` becomes true. Existing saved unfinished sessions retain their current challenge.
- Score reporting is only triggered at the genuine WIN state after all four rounds.
- Model checks remaining challenges before stopping alarm effects; snooze-added games remain required.
- All code is local; no network calls or dependencies.
- iOS retains OS-level Stop; the app does not and cannot disable it.

## Release checks still required
- Full Xcode build/sign/run (not available in Linux container).
- iPhone/WKWebView game round lifecycle at 320–430px and Dynamic Type/VoiceOver.
- Alarm sound + flashlight lifecycle in real hardware, app background/foreground, lock-screen and simultaneous alarms.
