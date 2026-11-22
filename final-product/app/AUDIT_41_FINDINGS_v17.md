# SnoozeLose — 41-Finding Audit Repair Tracker

Source audit: `SnoozeLose_v16_Detailed_Error_Audit(2).txt` dated 2026-11-21.

**Important scope change:** User asked not to modify or replace games; prebuilt games are coming separately. Thus gameplay findings are explicitly deferred, not claimed fixed.

| # | Status | Evidence / next action |
|---:|---|---|
| 01 | Platform constraint / copy corrected | iOS Stop cannot be disabled; promise clarified. |
| 02 | Implemented; device test pending | Completion invokes system stop(id:) alongside foreground cleanup. |
| 03 | Implemented; device test pending | Snooze schedules an AlarmKit timer where authorized; notification fallback otherwise. |
| 04 | Partially addressed | Foreground effects explicitly stop on background; live session persists. iOS delivery independent. |
| 05 | Scope clarified | Emergency silence affects foreground audio only; cannot prevent system Stop. |
| 06 | Implemented in source | Permission flow runs during scheduling; missing permission is Not Armed. |
| 07 | Implemented in source | Delivery states and recoverable editor errors; editor waits for success. |
| 08 | Partially addressed | Foreground notification opens challenge; background requires user/OS activation. |
| 09 | Implemented in source; test pending | Different IDs queue instead of playing one alarm against another session. |
| 10 | Unverified release gate | No Xcode build/sign or locked-iPhone overnight test available here. |
| 11 | Unresolved separate platform milestone | Android project not in supplied iOS source. |
| 12 | Deferred — prebuilt games | User will supply games; AI puzzle generation is not included. |
| 13 | Deferred — prebuilt games | Krillion renderer/logic will be provided or designed when game bundle arrives. |
| 14 | Deferred — prebuilt games | Baseball game not implemented in this repair. |
| 15 | Deferred — prebuilt games | Four-stage perception sequence remains with upcoming game work. |
| 16 | Audit fact corrected / games deferred | Original DOCX specifies -1 per 10 ms and average >=70; audit misread. |
| 17 | Deferred — prebuilt games | Counting game logic untouched. |
| 18 | Deferred — prebuilt games | Counting generator untouched. |
| 19 | Deferred — prebuilt games | Word dictionary validation untouched. |
| 20 | Deferred — prebuilt games | Word board attempt policy untouched. |
| 21 | Deferred — prebuilt games | Daily crossword generator untouched. |
| 22 | Deferred — prebuilt games | Crossword alternate remains existing partial implementation. |
| 23 | Implemented in source | Snooze button shows no additional challenge once cap reached. |
| 24 | Implemented in source | Practice sessions are transient and blocked while live session exists. |
| 25 | Implemented in source | Global serialized scheduling queue with generation invalidation. |
| 26 | Partially addressed | Default/Silent labels accurately state AlarmKit vs foreground/notification scope. |
| 27 | Scope corrected | Haptic and flashlight controls clearly marked foreground-only. |
| 28 | Implemented in source | Active My Alarms has Edit/Delete/Retry/Test/On-Off. |
| 29 | Implemented in source | Active alarm list and editor show delivery and feedback. |
| 30 | Implemented in source | Removed duplicated old CSS cascade; one home.css. |
| 31 | Browser-verified; native pending | 320/375/390/430pt in-memory screenshots pass; real WKWebView needed. |
| 32 | Implemented; device test pending | Pet settings moved to top-level dialog independent of narrow iframe. |
| 33 | Implemented in source | Legacy buddy modal removed, native dialog used with built-in ARIA/focus. |
| 34 | Deferred — prebuilt games | Keyboard/crossword accessibility to be reviewed with incoming package. |
| 35 | Deferred — prebuilt games | Word-shake issue left for incoming game code. |
| 36 | Implemented in source | One home stylesheet, design tokens, fewer override layers. |
| 37 | Mostly implemented | Page metadata/favicon and user copy cleaned; OG URL needs published domain. |
| 38 | Implemented in source | Bundle version 1.7 build 17; README/pet title updated. |
| 39 | Partially addressed; profiling pending | Fog uses on-demand rAF; old snow/extra loops removed; no Instruments data. |
| 40 | Implemented in source | Unused home CSS/JS/native dashboard and unrelated web assets pruned. |
| 41 | Human review required | Asset licensing and App Privacy materials still unverified. |

## Release decision

This is **not** an App Store-ready or dependable sole wake-up alarm. All source-only changes and browser checks are marked separately from iPhone hardware acceptance. Follow the QA matrix and integrate the upcoming games before publishing.
