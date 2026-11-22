# SNOOZELOSE — PRODUCT REQUIREMENTS & UX INTEGRATION DOCUMENT
Version: 1.1 / review date: November 21, 2026
Document type: Product review, implementation inventory, UX specification and acceptance criteria
Basis: Uploaded “Instructions Game Alarm: SnoozeLose” (5 pages); SnoozeLose PebbleGlass v10 project; supplied TIDAL reusable art/animation source.

## 1. Executive summary
SnoozeLose is an alarm app that challenges users to finish mini-games to dismiss an alarm. Each snooze adds one required game, capped at four extra games. The app is intended for iPhone and Android, and its game catalog is intended to produce fresh content daily. The experience should feel playful and interactive, while the core alarm status, challenge progression, and dismissal controls remain unambiguous.

IMPORTANT STATUS DISTINCTION: The supplied implementation is an iOS SwiftUI/Xcode project, not a finished cross-platform application. It includes a WKWebView-based illustrated home, a native alarm editor and native challenge views. It is NOT yet complete against the full original product requirements. This document does not declare unimplemented items finished.

## 2. Design authority and constraints
UX team owns: information hierarchy, typography, spacing, responsive layouts, colors, interactive mascot articulation, fog/cloud behavior, feedback, motion/accessibility presentation, error-state presentation and usability testing.
Product/engineering owners retain authority over: game rules and scoring, which games count toward a snooze, AI generation, permitted switching, completion/dismissal rules, alarm policy, sound/vibration, system permissions and Android architecture.
No feature in this document should silently change the five-page requirements.

## 3. Product rules from source requirements
FR-01: Users create alarms that ring at a user-selected time, with custom ringers and vibration.
FR-02: A game is presented when the alarm rings; playing and completing the required game(s) is the proposed in-app dismissal path.
FR-03: Every snooze adds one game, up to four added games.
FR-04: Daily content should be new, with AI-generated variations requested in the original document.
FR-05: The intended platforms are iPhone and Android; desktop testability is requested for the four-stage game.
FR-06: Game concepts include Wordle, mini-crossword, Krillion and Google Baseball, adapted into SnoozeLose's own visual language.
FR-07 (Wordle): valid five-letter words; green = correct position, yellow = present elsewhere, gray = absent. Specific original UI colors: background #E0FFFF; keyboard #6A5ACD.
FR-08 (Krillion): easier prompts to obtain an echo; after two echo failures, permit switching to a different random non-Krillion game.
FR-09 (Crossword): common, easy clues; after five minutes without completion, permit switching to a different non-crossword game.
FR-10 (Four-stage perception sequence): (1) five-second dot count, -3 points per count error; (2) projectile trajectory shown for one-third of path, predict landing, -2 points per percentage point error; (3) reproduce four presented beats and eight independent taps, -1 point per 10ms error; (4) split line by percentage/fraction, -1 point per percentage point error. Each stage starts on a 100-point scale; average all four. Average >=70 is a pass; otherwise replay the sequence.

Open product definitions: exact baseball mechanics; exact AI model/content validation process; rules for repeat puzzle availability offline; how the four-stage sequence counts as a single snooze-added game; exact system-alarm dismissal limitations; whether snoozing remains available after the fourth added game. Do not extrapolate unstated rules.

## 4. Supplied code: verified inventory
Technology: SwiftUI + UIKit, WKWebView for the illustrated home; SVG/HTML/CSS/JavaScript local assets; UserDefaults local alarm/session persistence; AlarmKit conditional on iOS 26+; user notifications as fallback.
Home navigation: PebbleWorldView is the current WindowGroup root. Web-to-native actions: `add`, `alarms`, `settings`, `test`. Bottom native dock opens alarms or creation. The native app supplies alarm editing, notifications and game challenge screens.
Alarm editor: time selection, title, ringtone (Default, Sunrise, Pulse, Silent), vibration, in-app flashlight and enabled toggle. Alerts and permission controls are in code.
Scheduling: recurring daily time; AlarmKit used when available/authorized, with notification fallback. Apple system Stop action remains available. Cannot guarantee that puzzle completion is the exclusive way to stop an alarm while the phone is locked.
Session model: stores puzzle progress, snooze count, scheduled resume time. One initial game, one added game per snooze up to four additions. Snooze interval is hard-coded to five minutes as a prototype choice, not specified in the user's original document.
Implemented challenge types: Word Guess, Quick Count, Mini Crossword. **Not implemented in supplied code:** Krillion, baseball, projectile tracking, rhythm matching, percentage line splitting, 4-stage average pass/fail flow, AI puzzle generator, native Android version.
Word Guess: uses a fixed, curated offline five-letter answer set, chosen deterministically from a day-derived seed. This is NOT AI-generated daily content and input acceptance does not currently implement a full valid-word dictionary check. The design does use the requested #E0FFFF and #6A5ACD colors.
Quick Count: displays dots for five seconds and computes 100 - 3 × absolute count error. The currently implemented completion rule demands an exact count, so it is not equivalent to the full four-stage average-score requirement.
Mini Crossword: currently a static 3×3 word square. It is not a new generated daily crossword. A timed replacement path exists in the supplied game view and should be explicitly regression-tested on-device.
No independent Xcode compilation/device QA has been completed in this editing environment.

## 5. UX design objective
Create a single coherent, highly interactive home screen that prioritizes the slogan, one mascot and a clear path to alarm creation/management. Use the supplied TIDAL art direction as a reference, but brand the screen as SnoozeLose. Keep fog as ambient decorative movement; do not mask essential information. Use one distinct hero character to prevent visual confusion.

Visual hierarchy on home:
1. Brand/header and product context.
2. Main “WAKE UP. LEVEL UP.” headline, large and readable.
3. One articulated Pebble SVG, with independently moving eyes, wings, feet, breathing and expressions.
4. Three deliberate character actions: Wave, Dance, Fish, with visible dialogue feedback.
5. Frosted-glass mission card: clear purpose, Set Alarm action and How It Works action.
6. Native dock: next scheduled alarm and a one-tap alarm-creation action.

Design tokens: ice-blue layered gradients, deep blue ink, mint green primary actions, translucent pale glass; consistent padding, radius and high-contrast typography. No gratuitous purple accent other than explicitly requested game UI colors.

## 6. Changes actually made for v1.1
CH-01: Removed the extra Pip penguin from the home scene; removed giant background penguin art. Exactly one hero Pebble character remains on the home.
CH-02: Removed the duplicated animated launch-screen Pebble so it no longer briefly creates another character or forces a pre-home introduction.
CH-03: Increased and emphasized “WAKE UP. LEVEL UP.” from the previous constrained 31–45px rules to a responsive, larger main title, with compact-screen adjustments.
CH-04: Reworded the small home eyebrow and subheading to clarify the product purpose; revised the mission card copy to make the alarm action clear.
CH-05: Removed the duplicate bottom HTML CTA section that competed with the frosted mission card and native alarm dock. The mission card and native dock still provide functional alarm creation.
CH-06: Refined the existing glass mission card, including button sizing, spacing and high-contrast copy.
CH-07: Repositioned the single Pebble hero, character controls, clouds, motion toggle and dialogue to reduce collisions; added compact-height and narrow-width responsive rules.
CH-08: Kept local touch fog, the SVG joint animation and independent cloud/snow effects. No image-translation-only substitute was added.
CH-09: Preserved WKWebView action wiring, alarm model and persistence keys, editor, game screens, audio files, app icon and Xcode project metadata.
CH-10: Added `css/snoozelose-home-v11.css` as an explicit last-in-cascade home refinement layer, avoiding edits to original reusable source CSS.

Exact files modified: `SnoozeLose/PebbleWorld/index.html`.
Exact files added: `SnoozeLose/PebbleWorld/css/snoozelose-home-v11.css`, this PRD and CHANGELOG files.
Native Swift logic was intentionally NOT changed in this pass.

## 7. UX interaction contracts
Alarm creation: Press Set Alarm on glass card or plus in dock -> existing native AlarmEditor sheet -> set desired properties -> Save -> return to home. No simulated button or fake submission.
Alarm list: Tap dock -> PebbleAlarmsSheet -> enable/disable or create. The sheet currently lacks an edit/delete surface even though SnoozeDashboard contains richer controls; improving access to existing edit/delete behavior is a recommended follow-up, not part of this patch.
How It Works: Tap -> native HTML modal explaining the existing workflow; close on button or background.
Character: Tap Pebble -> animated dance. Wave/Dance/Fish -> character-rig action and speech bubble. Move pointer -> tracked eyes; touch move -> fog clearing. Pause Motion -> disable ambient animation; should respect OS reduced-motion preference.
Alarm test: Existing native `test` bridge exists but is not surfaced on the redesigned single-screen home; no false test control is added.
Alarm running: Native WakeChallengeSession opens from an alarm interaction and uses existing model state. Snoozing updates required count and schedules another notification. Dismiss remains conditional on completion in native model; this does NOT prohibit OS-level Stop controls.

## 8. Quality bar & acceptance tests
QA-01: Launch iPhone portrait screen with only one visible Pebble; no giant/pip/intro duplicate.
QA-02: The full slogan is comfortably readable at common 320, 375, 390 and 430 CSS-pixel widths; no overlap with top header.
QA-03: One primary alarm-creation action is prominent; secondary information is clearly secondary.
QA-04: Character, mission card, dock and controls do not overlap at shorter view heights, with native safe-area/insets included.
QA-05: Wave/Dance/Fish, motion toggle, Help and alarm bridge actions remain interactive.
QA-06: Fog touches do not steal button events; animations pause appropriately; reduce-motion mode is respected.
QA-07: Alarms saved before an update remain available if app's bundle ID and user defaults remain intact.
QA-08: Verify actual alarm playback/permission/background/lock-screen behavior on a physical iPhone, iOS 26+ and an older supported iOS target.
QA-09: Verify game completion, snooze increment (max four added), resume, alternate crossword and alarm dismissal.
QA-10: Verify accessibility labels, 44-point minimum mobile touch targets where feasible, VoiceOver order, contrast, and font scaling.

Verification completed in this environment: archive extraction and source inspection; static HTML selector/assertion checks; JavaScript syntax checks; Swift parser check where compatible. Browser device screenshots and live Xcode/device build were not available/reliable, so QA-04, QA-06 and QA-08 remain manual acceptance gates.

## 9. Prioritized next engineering/UX backlog (not included in the patch)
P0: Validate Xcode build; install on real iPhone; verify alarms, default actions and actual lock-screen limitations. Inspect short-height screens in WKWebView within native bottom safe area.
P0: Clarify non-bypassable challenge expectation relative to iOS system Stop. Do not claim impossible enforcement.
P0: Make home alarm list provide edit/delete, next alarm context and concise schedule/error feedback while reusing existing model methods.
P1: Build a shared native design system for AlarmEditor, WakeChallengeSession, Word Guess, Count and Crossword consistent with the frosted home style.
P1: Implement unbuilt game types, correct four-stage scoring and all requested replacement constraints; require product approval for unspecified mechanics.
P1: Build valid-word checking and AI daily puzzle generation with safe, locally cached/offline fallback after agreeing on product rules.
P1: Implement full crossword generation and difficulty validation; avoid obscure clues.
P1: Plan Android architecture separately with Android alarm/background restrictions.
P2: Optimize fog for battery and memory, test 30/60fps constraints; provide reduced-motion and reduced-transparency alternatives.
P2: Add end-to-end automated interactions, on-device visual QA, accessible touch sizing and landscape/tablet scope clarification.

## 10. Risks
- AlarmKit OS behavior: impossible to guarantee game-only stopping through standard OS alarm controls without an explicitly verified permissible approach.
- Local WKWebView rendering differs from generic desktop Chromium; actual device tests are required.
- Heavy animation and full-screen canvas can hurt battery; fog should be throttleable.
- Referenced visual assets come from user-supplied source packages; redistribution rights should be checked before public release.
- Original requirements call for Android and AI, but current code implements neither.

## 11. Delivery
`SnoozeLose-PebbleGlass-v11-UX-FIXED.zip` contains the modified iOS Xcode project plus PRD and changelog.
`SnoozeLose_PRD_v11.txt` is a text copy of this document. `SnoozeLose_CHANGELOG_v11.txt` lists precise source edits.
This is a targeted home-screen visual correction, not a claim that the full product PRD is already implemented.
