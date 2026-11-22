# SnoozeLose v1.8.5 — Perception Set integrated (Build 22)

## Open in Xcode

1. Open `SnoozeLose.xcodeproj` in Xcode.
2. Choose the SnoozeLose target, set your own development team under Signing & Capabilities, and select your iPhone.
3. Choose Product > Clean Build Folder, then Run.
4. In the app, set an alarm and tap My Alarms > Test. Practice mode starts with Perception Set without touching a scheduled alarm.
5. For a live test, schedule an alarm a few minutes ahead, keeping a backup alarm.

## What is now included

- The supplied self-contained `SnoozeLose/PerceptionSet/index.html` has been bundled as a real Xcode resource.
- New alarm/practice sessions start with Perception Set: Count, Track, Angle, Split.
- Real victory is 4 stage scores averaging 70/100 or higher; failed runs do not unlock the challenge.
- Its native full-screen presentation removes the fake browser phone border and status bar.
- The host checks a per-view token, four score values, and the arithmetic average before calling `model.complete(item)`.
- An unfinished challenge keeps the normal native alarm lifecycle. Snooze-added challenges must also be finished.
- All original Pebble and alarm code is preserved.

## Important limitations

- This project has been tested in a Chromium browser, and the Swift files passed syntax parsing. It has not been fully compiled in Xcode or tested with a real iPhone alarm.
- Apple's system Stop controls cannot be blocked. The app must not be marketed as unbypassable.
- Existing unfinished sessions persist their old challenge selection; Perception Set is first for NEW sessions.
- The supplied file uses an ANGLE stage rather than the previously discussed RHYTHM stage. It was preserved as supplied.
- Android and other prebuilt games have not been integrated.

Read `PERCEPTION_SET_INTEGRATION_v185.md` for the integration details and `PERCEPTION_SET_QA_v185.md` for validation and remaining device tests.
