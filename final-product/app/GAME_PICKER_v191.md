# SnoozeLose v1.9.1 — Explicit game selection

## Implemented

- Alarm editor now offers a clear game selector: **Perception Set** or **Word Guess**.
- **Krillion** is shown as unavailable until its missing source modules arrive.
- Each `WakeAlarm` now persists `game` through `Codable`. Existing alarms
  without that field decode as **Perception Set** (not random).
- New and practice sessions use the saved alarm's game, without random draws.
- Snoozes keep the assigned game; the active session survives edits.
- Missing game resource or Word Guess preparation error does not silently
  replace a user's selection with another game.
- Alarm list displays the assigned game.
- The uploaded third-game Expo shell is archived in
  `ThirdGame_Expo_Reference_ONLY/`; it is not part of the iOS build.

## Third-game blocker

The user provided `App.js`, `package.json`, `package-lock.json`, `app.json`,
and `README(2).md`, **but not `src/krillion/KrillionPuzzleScreen` or
`src/krillion/puzzles`** (both imported by `App.js`). The third game is not
playable; preserving these files does not constitute game integration.

## Verification

Parse Swift sources, validate project format, check that the existing two
bundles remain present and confirm the Expo reference is excluded from the
iOS target. Full Xcode compilation and real-iPhone alarm delivery require Mac
hardware and are not certified here.
