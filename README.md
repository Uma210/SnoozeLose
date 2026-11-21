# SnoozeLose

SnoozeLose is a planned iPhone and Android alarm app. When an alarm rings, it reveals one puzzle. Completing that puzzle is the only dismissal action in the app. There is no snooze.

## Alarm and puzzle flow

1. The user sets a one-time or recurring alarm.
2. The app uses AI to prepare a distinct puzzle for each scheduled occurrence ahead of time and stores it on the device. A Monday alarm created Sunday evening gets its puzzle Sunday evening. Multiple alarms on the same day each get their own puzzle. Recurring alarms need a new puzzle prepared in advance for each occurrence.
3. At the scheduled time, the alarm sounds and vibrates, and the puzzle becomes available. The wake-up flow uses the stored puzzle so it can run offline.
4. The app checks the solution and dismisses the alarm when the puzzle is complete.

## Team work

Each of the four contributors owns one game. Assign owners before game development begins.

| Game | Scope |
| --- | --- |
| Wordle-style word guessing | Original interface and puzzle content |
| Mini crossword | Original interface, grids, and clues |
| Krillion | Game instructions to follow |
| Percptile | Game instructions to follow |

Use a branch per game and open pull requests against `main` once the repository has a shared remote. Coordinate on how each game receives a prepared puzzle and reports completion before integrating with the alarm flow.

## Platform behavior to verify

Test sound and vibration with the app closed, the phone locked, and Do Not Disturb or Focus enabled. Apple’s AlarmKit supports alarms that override Focus and Silent mode and provides system-level Stop behavior. Confirm how that affects puzzle-only dismissal before committing to the iPhone experience. Android supports exact clock alarms, with delivery and presentation subject to permissions and device settings.

- [Apple AlarmKit documentation](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit)
- [Android exact alarm documentation](https://developer.android.com/develop/background-work/services/alarms)
