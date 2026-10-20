# Implementation Plan - Fix SettingsScreen Errors

This plan addresses the compilation errors in `settings_screen.dart` that occurred because the `UserProfile` model was updated to use a time-based subscription (`isPremiumActive`) instead of a simple boolean (`isPremium`), and a null safety issue with the Firebase User object.

## Proposed Changes

### [MODIFY] [settings_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/settings_screen.dart)
1.  **Fix `isPremium` reference**: Change `snapshot.data?.isPremium == true` to `snapshot.data?.isPremiumActive == true` to match the updated `UserProfile` model logic.
2.  **Fix `User?` nullability**: The Firebase `currentUser` can technically be null. In the `onTap` handler where `_showPaymentDialog(context, config, p, user)` is called, add a null check (`user!`) since we know the user must be logged in to access this part of the settings screen, or conditionally execute the logic.
3.  **Relocate `_showPaymentDialog`**: Ensure `_showPaymentDialog` is correctly placed within the `_SettingsScreenState` class so it is recognized and the "unused declaration" warning disappears.

## Verification Plan

### Manual Verification
- The Dart analyzer should report no errors in `settings_screen.dart`.
- The app should compile and run successfully.
