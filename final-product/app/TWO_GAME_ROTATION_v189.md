# SnoozeLose 1.8.9 — two-game random rotation

- Installed games: Perception Set (local HTML) and SnoozeLoseWordGame (supplied SwiftUI source).
- One assigned game per new alarm occurrence. Each new alarm randomly selects either installed game with equal probability; repeats across alarms are possible. Once selected, the game remains assigned for that alarm, including through snoozes.
- Snoozing retains the same game; it does not add another game.
- Word-game puzzles are prepared with the challenge item's UUID and persisted by the supplied SnoozeLoseWordPuzzle storage implementation.
- Repeated word guess attempts retain the same secret answer. Six failed guesses show Try again, not a success event.
- Completing a word puzzle calls the existing SnoozeModel.complete(item) only after the occurrence ID and active item match. The existing system only stops the foreground and system alarm once the game is genuinely solved.
- On successful completion the word game returns home; practice mode ends without changing a live alarm.
- Both game sources remain bundled; older counting/crossword prototypes are not included in the random pool.
- The app still requires an Xcode build and iPhone alarm test. Do not rely on it as your only wake-up alarm during testing.
- Word game supplied dictionary is a large embedded wordlist; it may include obscure entries and should be curated for difficulty before publication.
