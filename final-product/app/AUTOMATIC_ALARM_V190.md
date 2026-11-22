# SnoozeLose v1.9.0 — Automatic Challenge Presentation

## Root cause
Previous versions started a live game only through notification response, AlarmKit Open App intent, manual Test, or Play challenges now. They did not subscribe to AlarmKit `.alerting` updates, nor check for a foreground due time. A still-open app could therefore sit at home past alarm time without opening its assigned game. Snoozed sessions also resumed only on scene activation instead of when the timer elapsed in an already-open app.

## Changes
- `SnoozeModel.swift`: automatic foreground monitoring with iOS 26+ AlarmKit `alarmUpdates`, snapshot on activation, and a once-per-second due-time fallback limited to a 90-second due window. Persist expected per-alarm trigger dates and deduplicate repeated state updates. Resume expired snoozes automatically. Cancel obsolete snooze reminders on activation. Keep one game and the existing random two-game selection.
- `SnoozeLoseApp.swift`: starts/stops monitoring with scene lifecycle and installs native one-second tick.
- `PebbleWorldView.swift`: dismisses auxiliary sheets when a live challenge starts so the full-screen game can appear.
- No gameplay assets, scoring, Pebble animation, alarm schedule configuration, or permissions were changed.

## iOS constraints
- Foreground: when SnoozeLose is open, the selected game presents automatically at alarm time and the app starts its foreground alarm effects.
- Locked/closed/background: iOS/AlarmKit delivers the system alert. The user must choose **Solve Challenge** to open the app. iOS does not allow an app to force itself into the foreground or prohibit its system Stop control.
- iOS 16-25: local notification fallback can notify but cannot sustain continuous alarm behavior while app is closed.
- If alarm permission is denied, a foreground session can still be presented while app is running, but no background alarm is guaranteed.

## Test matrix for iPhone
1. Keep app in foreground and set a new alarm 2 minutes ahead. Do NOT tap Test. Verify game automatically appears at the scheduled minute, shows 0/1, and either Perception Set or Word Guess is selected.
2. Solve game, check sound/torch effects stop, and verify another presentation does not occur within the same minute.
3. Snooze an active game; leave app foreground for five minutes and verify the same game resumes automatically.
4. Set another alarm; lock screen and verify system AlarmKit alert. Tap Solve Challenge and verify correct game opens. Then try quitting app and repeating.
5. Test two overlapping alarms, background/foreground, an edited alarm, an alarm switched off, and permissions denied.
6. Keep Apple Clock backup alarm until hardware tests succeed.

## Verification scope
Swift parser and static source checks are not an iOS compilation. Full Xcode build, AlarmKit events and locked-device alarm reliability require physical-device validation.
