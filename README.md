# SnoozeLose — iOS Alarm + Pebble (v1.6 Natural Rig)

SnoozeLose is a SwiftUI iPhone alarm project with an interactive, animated penguin companion, **Pebble**. The project includes its Xcode sources, bundled web experience, graphics, sounds, and project documentation. This repository combines the original **v16 Stable Side Rails** app with the updated **Pebble Fluid Pet v1.6 Natural Rig** character.

## Run the iPhone app

1. On a Mac, install a recent version of **Xcode** with the iOS SDK.
2. Open **`SnoozeLose.xcodeproj`** (the project file in this folder).
3. In Xcode, select the **SnoozeLose** app target and your desired iPhone simulator or device. Configure **Signing & Capabilities** for your Apple team if needed.
4. Build and run with **Cmd + R**.

The main app is under `SnoozeLose/`. SwiftUI and the alarm logic stay in their respective Swift source files. The companion web files and their assets are bundled under `SnoozeLose/PebbleWorld/`.

## Preview the web UI separately

From the repository root, run:

```sh
cd SnoozeLose/PebbleWorld
python3 -m http.server 8000
```

Open **http://localhost:8000** for the home interface. You can also visit **http://localhost:8000/pebble-pet.html** for Pebble’s standalone playroom. This is a **browser preview** of the web experience; native iOS alarm functions require the Xcode app.

## How the Pebble integration works

- `SnoozeLose/PebbleWorld/index.html` displays Pebble in an embedded iframe using `pebble-pet.html?embedded=1`.
- `SnoozeLose/PebbleWorld/pebble-pet.html` is the **updated v1.6 natural-rig** character, with grounded feet, articulated head/flippers, expressions, and playful interactions.
- `SnoozeLose/PebbleWorld/js/pebble-home-integration.js` relays presentation-only commands to the pet. Native Swift code controls alarms; the character cannot alter alarm state.
- Microphone interaction requires permission and a compatible secure context. Speech and audio support depend on browser/WKWebView platform behavior.

## Project documentation

The original PRD, integration notes, change logs, and QA reports remain included. Some original reports refer to older versions: refer to this README for the packaged Pebble version. No third-party services or install-time web build step are required for the included character assets.

## Verification limits

This package has been assembled and statically checked for local web asset references, embedded JavaScript syntax, and the presence of the Xcode project/source files. **An Xcode build, iPhone runtime, permission flow, and alarm reliability have not been verified in this environment**. Test these before submitting or presenting the app as production-ready.
