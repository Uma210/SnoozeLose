# Pebble v3 -> SnoozeLose v1.4 Integration

## Selected pet features
- Genuine layered SVG: independent wings, eyes, mouth, feet, eyebrows
- Belly poke / head poke with escalation / drag-pet / swipe reactions
- Idle reactions and sleep after 30 seconds
- Fish feeding with animated object and chewing, ball toy
- Speech: “Bro, wake up!” and randomized wake-up lines via platform speech synthesis
- Microphone record-and-repeat feature is included behind a user-initiated MIC action, subject to device permissions, secure contexts, and WKWebView support; verify on device
- Pitch, volume, sensitivity and mute in pet settings
- Reduced motion and procedural sounds

## Deliberately not integrated
- Standalone pet brand header, duplicated home screen, and duplicated background fog/clouds
- Dedicated pet features inside alarm dismissal/challenge screens: no change to alarm rules
- Automatic microphone activation or automatic spoken audio when alarms ring (would interfere with alarms and permissions)

## Boundaries
Swift SnoozeModel/WakeRinger/ChallengePlayer unchanged. Pebble runs inside PebbleWorld/index.html as same-bundle iframe of pebble-pet.html with embedded mode. Parent communicates through typed postMessage commands. Pet cannot call snoozeNative or alter alarms. Native lifecycle tells pet to stop microphone/speech when the app goes inactive or a challenge opens.

## Checks and limitations
Static scripts must pass JS syntax and project syntax parsing; inspect iPhone viewport rendering. Xcode compilation and physical-device WKWebView recording/playback remain unverified until executed on an iPhone. AlarmKit/system dismissal limitations remain unchanged.
