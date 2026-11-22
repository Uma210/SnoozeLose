# SnoozeLose 1.8.6 — Snoozed challenge visibility repair

## Cause verified
The screenshot shows a saved session with `resumeAt` in the future, so `WakeChallengeSession` shows the rest/snooze branch and intentionally hides the game. This is not a missing Perception Set asset. There are five assigned games because snoozing can add four games to the original challenge.

## Source changes
- Added `SnoozeModel.playPendingChallengesNow()`: invalidates and cancels the scheduled snooze, clears `resumeAt`, preserves all assigned games/scores, then resumes the unsolved game and foreground effects. Does not complete a game.
- Migrates only a fully-unsolved, legacy session's first slot to the bundled Perception Set after explicit user tap. Preserves number of required challenges and snooze count.
- Shows an obvious **Play challenges now** action on the snoozed screen. Back to alarms remains secondary.
- Bumped project marketing/build version to 1.8.6 (23).

## What remains unchanged
Game HTML, all four scoring rules, success validation bridge, native home UI, Pebble, alarm-scheduling core, and accessibility behavior outside this screen. iOS system Stop controls cannot be disabled.

## Test
Run a new test alarm, snooze it and open the challenge during the snooze period. Tap Play challenges now; it should immediately show Perception Set. The timer should be canceled, and progress remains 0/2 (or current count). Try with a saved legacy session. Verify a win is required before `model.complete` is called. Test on a physical iPhone.
