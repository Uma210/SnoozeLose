# Krillion for Android

Krillion is a standalone Android app for Android 8.0 (API 26) and newer. It runs the bundled Krillion game offline and saves prompt history on the device. The Android application ID is `io.github.uma210.krillion`.

## Build and install

Open this directory in Android Studio with Android SDK Platform 35, Android SDK Build-Tools 35.0.0, and JDK 17 or 21. You can also build from a terminal with `ANDROID_HOME` set to the SDK location.

```sh
./gradlew :app:assembleDebug
```

On Windows, use `gradlew.bat`. The debug APK is generated at `app/build/outputs/apk/debug/app-debug.apk`. Install it on a connected test device with `adb install -r app/build/outputs/apk/debug/app-debug.apk`, or open the APK on the phone and follow Android’s install prompt.

The debug APK is signed for testing. A store release requires a release signing key and store configuration. Keep signing keys and local SDK paths out of Git.

## Game source

The shared game lives at `../web/index.html`. Gradle bundles it into the APK during the build.
