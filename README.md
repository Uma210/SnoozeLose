# SnoozeLose

SnoozeLose is a planned iPhone and Android alarm app. When an alarm rings, it reveals one puzzle. Completing that puzzle is the only dismissal action in the app. There is no snooze.

## Alarm and puzzle flow

1. The user sets a one-time or recurring alarm.
2. The app prepares a distinct puzzle for each scheduled occurrence ahead of time and stores it on the device. For the word game, it selects an unused answer from the bundled English word list. A Monday alarm created Sunday evening gets its puzzle Sunday evening. Multiple alarms on the same day each get their own puzzle. Recurring alarms need a new puzzle prepared in advance for each occurrence.
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

## Run the word game

Install the app dependencies with `npm ci`, then run `npm start`. Open the app in Expo Go for SDK 54 or an SDK 54 development build. The standalone preview opens directly to the alarm puzzle screen with an unused five-letter word from the bundled list. It works offline. Run `npm test` for the game-rule tests.

## Connect the word game to the alarm

1. When scheduling a word-game occurrence, choose a stable string ID for that occurrence, then await `prepareWordPuzzle(occurrenceId, selectDatabaseWord)` from `src/word-game/puzzles.js`. Mark the puzzle ready only after this resolves. Preparing the same ID again returns its stored puzzle. Each recurring occurrence needs its own ID.
2. When that occurrence fires, open `WordPuzzleScreen` with its `occurrenceId`, a display-ready `alarmTime`, and an `onSolved` callback. The screen reads the puzzle and submitted guesses from on-device storage and works without a network connection.
3. In `onSolved(occurrenceId)`, stop sound and vibration for that occurrence. Make the handler safe to call again for the same ID. If the app is reopened after a correct guess has been saved, the screen reports completion again so the alarm can finish. Pass `onWinAnimationComplete(occurrenceId)` to return home after the alarm stops and the win animation finishes.

The offline dictionary contains the four- through six-letter entries from [word-list 4.1.0](https://github.com/sindresorhus/word-list). New puzzles use only five-letter answers. Previously prepared puzzles keep their original answers. See the bundled dictionary license.
