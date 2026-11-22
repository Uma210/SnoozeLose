# SnoozeLose v1.8.7 — One game per alarm

## Requested behavior
- Each new alarm gets exactly **one** randomly selected finished/registered game.
- Perception Set is currently the **only** registered game, so every new alarm selects it until more supplied games are integrated.
- Perception Set's four internal rounds remain ONE game; users need an average of 70 to complete it.
- Snoozing delays the alarm but does **not** add games or reroll the game.
- Practice is also one game and never changes live alarm state.
- Older unfinished sessions with accumulated challenges are migrated to one active unsolved game. For a never-attempted old session, the first game is Perception Set when bundled.
- A new alarm session picks a new game; reopening/snoozing that session keeps its selection.

## Scope
- Modified SnoozeModel.swift, SnoozeDashboard.swift, PebbleWorld/index.html copy, project version/build.
- Did not change Perception Set logic, Pebble animations, audio/flash engine, scheduling integration, or native WebView bridge.

## Adding future games
After another prebuilt game is integrated, register its ChallengeKind in `installedGames` only when its actual resource bundle is verified. The chooser will then randomly select from installed options, preferring not to repeat the previous game when alternatives exist. Do not register incomplete prototypes.

## Testing / limitations
Static checks cannot establish actual AlarmKit scheduling or iPhone gameplay. Validate in Xcode on-device: one game per alarm, snooze does not increase count, pass/fail of all four perception rounds, legacy session migration, repeated alarms, and microphone/background behavior. iOS system Stop remains available.
