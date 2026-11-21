# Krillion for iPhone

Krillion is an offline iPhone app for iOS 15 and newer. It bundles the same game as the browser and Android builds and stores prompt history on the device. The bundle identifier is `io.github.uma210.krillion`.

## Run from Xcode

1. On a Mac, open `Krillion.xcodeproj` in Xcode.
2. Choose the **Krillion** scheme and an iPhone simulator to run without device signing.
3. To install on your own iPhone, select your Apple signing team under **Signing & Capabilities**, choose your connected iPhone as the destination, and run. If your team cannot register `io.github.uma210.krillion`, assign a bundle identifier your team controls.

For TestFlight or App Store distribution, archive and export the app through Xcode with the appropriate Apple Developer team and distribution signing.

Xcode bundles the shared game from `../web/index.html` during the build.
