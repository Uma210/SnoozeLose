# SnoozeLose 1.7.1 — Xcode compile fix

## Issue

Apple's `AlarmManager.shared.alarms` is declared `get throws` (iOS 26+), but two reads in `SnoozeModel.swift` did not handle errors. Xcode reported two compile errors (both are corrected).

## Changes

1. `reconcileSchedules()` now reads the AlarmKit list using `try` in `do/catch`, preserving notification fallback status when an AlarmKit lookup fails and displaying an explicit error otherwise. A thrown lookup no longer incorrectly marks alarms as definitively missing.
2. `testRinger(for:)` now uses a guarded `try`/`do/catch` read only when AlarmKit authorization is granted. If the system lookup fails, it avoids triggering a duplicate foreground ringer and surfaces the reason.
3. Bumped marketing version to `1.7.1`, build number to `18`.

## Separate user action: signing

The project cannot be signed without an Apple development team connected in Xcode. Select the SnoozeLose app target > **Signing & Capabilities** > enable **Automatically manage signing** > choose your Apple Team. If the team list is empty, sign in with your Apple Account in Xcode Settings > Accounts. For testing on an iPhone, select your device as the run destination. We did not insert an invented Team ID into the project.

## Validation limits

Swift parser checks cannot type-check Apple AlarmKit without the iOS SDK. Rebuild using your installed Xcode and iOS 26 SDK. No native Xcode build or device runtime test was performed in this container.
