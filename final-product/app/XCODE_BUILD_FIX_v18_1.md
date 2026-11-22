# SnoozeLose v1.8.1 — Swift initializer compile repair

## Reported error

`PebbleWorldView.swift` → `PebbleWebView.Coordinator.init(status:onAction:)`:
`'self' used before 'super.init' call`.

## Exact fix

After assigning the stored properties `status` and `onAction`, added `super.init()` **before** the delayed `DispatchQueue.main.asyncAfter` closure captures `[weak self]`.

This retains the 10-second WebView failure watchdog and retry behavior.

## Scope

Only `SnoozeLose/PebbleWorldView.swift` changed compared with v1.8.0. All other game code, alarms, character assets, interfaces, and Xcode configuration are byte-identical. This release note is new.

## What this does NOT solve

Xcode signing requires you to select your Apple team in Signing & Capabilities. A full framework type-check, Xcode build, and iPhone runtime alarm test cannot be completed in this environment.

## Build steps

Open `SnoozeLose.xcodeproj`, select the SnoozeLose app target → Signing & Capabilities → Team and your own Apple development team / Personal Team, enable automatic signing; then Product → Clean Build Folder and build.
