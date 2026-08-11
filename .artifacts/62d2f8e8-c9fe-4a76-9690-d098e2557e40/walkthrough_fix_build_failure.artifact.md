# Walkthrough - Fixing Build Failure (Kotlin Downgrade)

I have resolved the build error that occurred when trying to compile the `flutter_timezone` plugin.

## Changes Made

### 1. Reverted to Stable Kotlin Version
- **File**: [settings.gradle.kts](file:///D:/FlutterProjects/money_manage_app/android/settings.gradle.kts)
- **Change**: Downgraded Kotlin version from `2.2.20` to `2.0.20`.
- **Reason**: `2.2.20` is a future/unstable version that was causing compilation errors in the `flutter_timezone` library. Switching back to the stable `2.0.20` version ensures compatibility across all your project's plugins.

## Next Steps

To successfully build your app, please follow these commands in your terminal:

> [!IMPORTANT]
> **Rebuild the APK:**
> 1. Run: `flutter clean`
> 2. Run: `flutter pub get`
> 3. Run: `flutter build apk --release`

The build should now complete without the Kotlin compilation error.
