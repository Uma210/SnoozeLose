# SnoozeLose v1.7 — Product Requirements Document

**Status:** iPhone alarm infrastructure under validation; interactive Pebble implemented; **game content pending user-provided prebuilt package**. This document intentionally distinguishes implemented behavior from original product requirements.

## Purpose

SnoozeLose is a playful wake-up alarm app: choose a time, receive an OS-supported alert, and complete game challenges to mark the current wake-up session finished. Pebble is a character companion and does not control alarm scheduling or game outcomes.

## Target environments

- iPhone iOS 26+: AlarmKit system scheduled alarms, subject to user authorization and iOS controls.
- iPhone iOS 16–25: standard local-notification fallback, **not** equivalent to a persistent alarm.
- Android: part of original requirements, **not built in this iOS project**.

## Core alarm flow

1. Create/edit an alarm with time, name, enabled state, sound preference, and foreground-only vibration/flash effects.
2. On save, wait for OS scheduling outcome; display armed/system, armed/notification fallback, pending, or not armed/error. Do not silently treat saved configuration as a working alert.
3. At delivery, iOS presents its normal system controls. The user opens the challenge through the Solve Challenge action or notification; when app is already in the foreground, it can present the challenge automatically.
4. The host selects an assigned game and tracks the persistent live session. The game module reports completion; the user dismisses after all assigned items are completed.
5. Snooze for the current prototype default of 5 minutes. Each snooze adds one challenge until **four additional games** have been added. Subsequent snoozes do not increase the requirement count.
6. On successful dismissal, stop foreground effects, stop the relevant AlarmKit alert where possible and clear the current snooze timer/notification. Preserve the repeating schedule for future days.
7. A second alarm does not overwrite a first unfinished session: alarm IDs are handled deterministically and queued.
8. Practice runs transiently, does not schedule alarms or persist as a real live session and cannot be started over an unfinished live alarm.

## Pebble experience

- One layered SVG penguin with independently animated head, flippers, feet, face, eyes and reactions.
- The ice-blue home screen groups interactions on left/right side rails. Home screen includes Wake, Talk (permission-gated mic), Pet settings, Surprise, Dance, Fish and Ball.
- Speech and mic replay are local browser/WKWebView features; actual hardware permissions and playback require device tests.
- Parent-level settings controls pitch, volume, microphone sensitivity and mute. Reduce Motion and animation throttling should be supported.

## Game content — reserved for supplied prebuilt games

The original requirements specify Wordle-inspired word guessing, a Mini-Crossword, Krillion-inspired echo prompts, Google Baseball-inspired play and a four-stage perception challenge (count estimation, projectile tracking, beat tapping, percentage/fraction line splitting). Requirements include daily refreshed content, selected alternate-game conditions and the specified scoring rules. **These are NOT claimed complete in v1.7, and `ChallengePlayer.swift` is intentionally unchanged.** See `GAME_INTEGRATION_CONTRACT.md` before adding supplied games.

## Quality and release gates

AlarmKit verification, lock-screen delivery, background/Focus/Silent behavior, permission refusal and recovery, duplicate alarms, timer cancellations, accessibility, performance/battery and asset permissions are hard release gates. A pass on syntax or a web preview is insufficient. iOS system Stop is outside the game gate and cannot be made unavailable through this app.
