# Krillion for iPhone

Krillion is an offline iPhone app for iOS 15.4 and newer. The portrait layout adapts to the available screen height and leaves room for the iPhone’s notch and home indicator. Prompt history is stored on the device.

## Run from Xcode

1. On a Mac, open `Krillion.xcodeproj` in Xcode.
2. Choose the **Krillion** scheme and an iPhone simulator to run without device signing.
3. To install on your own iPhone, select your Apple signing team under **Signing & Capabilities**, choose your connected iPhone as the destination, and run. If your team cannot register `io.github.uma210.krillion`, assign a bundle identifier your team controls.

For TestFlight or App Store distribution, archive and export the app through Xcode with the appropriate Apple Developer team and distribution signing.

Xcode bundles the shared game from `../web/index.html` during the build.

## Add Krillion to a SwiftUI app

The game uses the restart dialog and dynamic viewport units introduced in iOS 15.4. [WebKit 15.4 release notes](https://webkit.org/blog/12445/new-webkit-features-in-safari-15-4/)

1. Add [`KrillionView.swift`](Krillion/KrillionView.swift) and [`index.html`](../web/index.html) to your Xcode app target.
2. In **Build Phases**, check that `KrillionView.swift` is in **Compile Sources** and `index.html` is in **Copy Bundle Resources**.
3. Present `KrillionView()` from a SwiftUI screen. To use the whole display, present it in a full-screen cover and apply `.ignoresSafeArea(.container)`.

```swift
import SwiftUI

struct KrillionScreen: View {
    var body: some View {
        KrillionView()
            .ignoresSafeArea(.container)
    }
}
```

If your app already bundles an `index.html`, rename the Krillion copy to `Krillion.html` and use `KrillionView(resourceName: "Krillion")`.
