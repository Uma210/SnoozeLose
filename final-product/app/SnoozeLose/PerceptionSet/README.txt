PERCEPTION SET — bundled and activated in SnoozeLose v1.8.5

The real self-contained HTML was supplied by the user as index.html.
The four rounds are: Quick count, Follow the flight, Read the angle, Split the line.
Each round awards 0–100; the game passes only with a four-score mean >=70.
A failed set requires Play again. No win notification is sent on failure.

The game remains separately playable as a standalone HTML file.
Inside SnoozeLose it is displayed without the fake device frame/status bar.
The native host injects SnoozeLosePerception at document start.
ONLY after the real four-round win does the bundled script call:
  window.SnoozeLosePerception.complete({won:true,average,scores,rounds:4})
The native host validates score count, range, average and unique per-view token.
No network is needed. iOS still allows system Stop and app switching.

To test from the native home screen: My Alarms > Test on a saved alarm.
For a new live session this is Challenge 1. A snooze can add other games.
Game completion calls model.complete(item). The alarm ends only after ALL
required challenges finish, with a system Stop remaining available on iOS.
