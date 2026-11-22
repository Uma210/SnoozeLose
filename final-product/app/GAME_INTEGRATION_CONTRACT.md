# Prebuilt Game Integration Contract (For Next Version)

**Historical contract for prebuilt games. Perception Set is now integrated in v1.8.5; the remaining games are pending.**

The new games should be integrated behind the already-used `ChallengePlayer(item:)` boundary. The host owns wake/alarm lifecycle; the game module only renders a game, accepts its assigned puzzle and invokes a completion callback when the prescribed rule is satisfied.

## Current host interface

- `ChallengeItem` contains `id: UUID`, `kind: ChallengeKind`, `puzzleSeed: Int`, and `solved: Bool`.
- The active screen calls `ChallengePlayer(item: challenge).id(challenge.id)`.
- On success, the module calls `model.complete(item)`.
- For an eligible alternative puzzle, it calls `model.replaceChallenge(item)`; the host chooses a different kind.
- `model.dismiss()` is offered only when all required items have been completed.
- `model.isPractice` differentiates demo sessions from saved live alarms.
- `model.snooze()` increments the challenge count up to four additional games; do **not** modify that in a game renderer.

## When the prebuilt games arrive

1. Inspect the supplied game assets/code, licensing, dependencies and supported platforms before integration.
2. Map each game to a stable `ChallengeKind` identifier without changing old persisted identifiers unexpectedly; add migration if identifiers change.
3. If a game has multiple ordered stages, let its module own stage progression and return **one outcome** to the alarm host when the approved game win condition is met.
4. Implement hints/replacement only where specified; reject completion requests from unsolved games.
5. Keep any internet/API calls away from alarm scheduling and provide an offline recovery policy agreed with the product owner.
6. Re-test practice, snooze cap, overlapping alarms, app backgrounding and full-screen game transitions.

**Do not reinterpret scoring rules.** The original user DOCX specifies -1 point per 10 milliseconds for beat timing and a >=70 average passing threshold for the four-stage perception game. The uploaded error audit incorrectly states otherwise. Preserve original rules when the new games are supplied.
