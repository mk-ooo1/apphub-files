# Implementation Plan - Fix Admin Panel Access & Update Button

I apologize for misunderstanding your previous request. I see now that the 7-tap Admin Panel and the Update Button we added previously are not functioning correctly, and you want to fix those features.

## The Problem
The `_handleDevTap` method is defined in `settings_screen.dart`, but because of a previous copy-paste error during file resolution, the tap counter `_devTapCount` might not be working correctly (e.g., losing state if the widget rebuilds unexpectedly) or the `AdminService` is failing to initialize/fetch data, causing the password dialog to never appear. Additionally, the Update Button might not be displaying if the `AdminService.watchConfig()` stream is throwing an error or hanging.

## Proposed Changes

### [MODIFY] [admin_service.dart](file:///D:/FlutterProjects/money_manage_app/lib/services/admin_service.dart)
- Update `getConfig()` and `watchConfig()` to be more robust. If the document `admin/config` does not exist in your Firebase database, `snapshot.data()` will be null, and the current code tries to read it, which might throw an error or return nothing, hiding the UI elements.
- We will ensure it forcefully creates the default document if it's missing, guaranteeing the stream and futures return data.

### [MODIFY] [settings_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/settings_screen.dart)
- Add a visual indicator (like a quick Snackbar saying "You are X steps away from being a developer") so you know the taps are actually registering.
- Ensure the `onTap` for the Developer tile is correctly hooked up to `_handleDevTap`.

## Verification Plan

### Manual Verification
1.  Open the App and go to Settings.
2.  The "Update App" button should immediately be visible under "About".
3.  Tap the "Developer" tile. You should see a tiny message counting down the taps.
4.  On the 7th tap, the password dialog MUST appear.
5.  Entering `admin123` MUST open the `AdminPanelScreen`.
