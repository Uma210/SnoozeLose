# SnoozeLose v1.8.8 — background alarm readiness

## Behavior by iOS version
- iOS 26+ with AlarmKit permission: SnoozeLose registers a recurring system alarm, not a WebView timer. Once confirmed, the alarm is shown as **System alarm armed** and can ring with the app backgrounded, closed or the phone locked. Users can stop it using system alarm controls; the game is not unbypassable.
- iOS 16–25 or AlarmKit unavailable/denied: a time-sensitive **local notification** is attempted if authorized. It cannot provide a continuously looping alarm and is affected by notification settings, including sound/Focus. Never describe it as a system alarm.
- In-app custom ringing/torch: foreground-only and not a substitute for system delivery. Flashlight does not remain on while the app is closed.

## Changes from v1.8.7
1. After `AlarmManager.schedule`, read back AlarmKit's scheduled alarm IDs before marking an alarm **System alarm armed**. If verification fails, show an explicit pending state. A failed read never triggers an unintentional second notification.
2. Keep the older-iOS notification fallback clearly identified as a notification. Time Sensitive notification entitlement/capability is NOT enabled, so Focus/Silent mode can suppress sound; no critical-alert bypass is claimed.
3. Version advanced to 1.8.8 build 25. No changes to game selection, Pebble, or the alarm's repetition pattern.

## Required real-device validation
1. On iOS 26+ open **My Alarms**, create an alarm 2 minutes in the future; approve the Alarms permission and verify **System alarm armed**.
2. Lock the phone, leave SnoozeLose, and check that the iOS system alarm rings at the correct time. Repeat after closing the app from the app switcher and after a normal phone reboot.
3. Tap **Solve Challenge** to open Perception Set. Complete all four stages and verify that successful completion stops active sound, with an average of at least 70.
4. Verify that pressing the system **Stop** button still stops the system alarm (iOS controls cannot be blocked).
5. Test snooze and recurring next-day delivery. Test Focus/Silent mode and screen locked. On older iOS explicitly verify local-notification behavior, not continuous ringing.
6. Deny AlarmKit and notification permissions, then verify the app displays **not armed** rather than pretending to have scheduled an alarm.
7. Keep an independent backup alarm throughout testing. This code has not been built or executed on an iPhone here.
