# Krillion alarm puzzle

Krillion runs inside SnoozeLose as a React Native screen. It uses the bundled prompt bank and portrait ocean artwork offline. An alarm can present it as soon as its prepared occurrence fires.

## Connect an alarm occurrence

1. Schedule the occurrence using the alarm service. Before marking it ready, await `prepareKrillionPuzzle(occurrenceId)` from `puzzles.js`. Use a distinct ID for each occurrence. Preparation for the same ID returns the stored dive and does not start its countdown.
2. When the alarm opens its puzzle route, render `KrillionPuzzleScreen` with `occurrenceId`, `alarmTime`, and `onSolved`. Keep the route mounted as the active alarm screen. If the host uses a navigation stack or a swipe-to-dismiss modal, configure that route to stay open while the occurrence is active.
3. In `onSolved(occurrenceId)`, stop the alarm sound and vibration for that occurrence and then remove its route. Keep that operation safe to retry. Krillion saves a completed dive before invoking the callback, and calls it again if the completed occurrence is reopened.

```jsx
<KrillionPuzzleScreen
  occurrenceId={activeAlarm.id}
  alarmTime={activeAlarm.displayTime}
  onSolved={async (occurrenceId) => {
    await stopRingingOccurrence(occurrenceId);
    clearActiveAlarm(occurrenceId);
  }}
/>
```

The completion signal requires seven finished prompts in a dive. A third miss offers a restart for the same alarm occurrence. The alarm keeps running while the player retries. The native screen handles Android’s Back action while it displays the puzzle. The host owns system alarm scheduling, app launch from an alarm, and audio and vibration control.

## Preview and checks

Run `npm ci` and `npm start`, then open the SDK 54 app and select **Preview Krillion alarm**. The foreground preview vibrates while the game is active and stops when the dive completes. Run `node --test src/krillion/rules.test.js` for the preparation, timeout, and completion checks.
