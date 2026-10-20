# Walkthrough - Restricting Free Users & Tracking Activation Requests

I have successfully restricted data entry for non-premium users and upgraded the Admin Panel to show all users, highlighting those who have requested activation.

## Changes Made

### 1. App Lockout for Free Users
- **[dashboard_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/dashboard_screen.dart)**: Wrapped the Floating Action Buttons (FABs) in a check for `isPremiumActive`. If the user is free or their subscription has expired, the FABs for adding contacts, banks, and splitting bills are replaced by a gray lock icon. Tapping it tells them to upgrade in Settings.
- **[contact_detail_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/contact_detail_screen.dart)**: The `Gave` and `Got` buttons are similarly locked for free users. They can still view all existing data and export reports, but they cannot add new transactions until you activate them.

### 2. Tracking Activation Requests
- **[user_profile.dart](file:///D:/FlutterProjects/money_manage_app/lib/models/user_profile.dart)**: Added `pendingRequestPlan` to the user profile.
- **[settings_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/settings_screen.dart)**: When a user taps the "I Have Paid" button, the app now writes to Firestore, setting `pendingRequestPlan` to the name of the plan they selected (e.g., "Monthly"), right before opening WhatsApp.
- **[ledger_service.dart](file:///D:/FlutterProjects/money_manage_app/lib/services/ledger_service.dart)**:
    - Updated `watchAllUserProfiles()` to show *all* users by removing the restrictive filter.
    - Updated the approval logic so that granting premium days automatically clears the `pendingRequestPlan` flag.

### 3. Admin Panel UI
- **[admin_panel_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/admin_panel_screen.dart)**:
    - If a user has a pending request, they now have a red "Requested" badge next to their name.
    - The subtitle clearly shows `Plan: [Plan Name]` in orange so you know what they paid for.
    - Added a "Revoke / Reject" option to the menu to clear requests without granting time.

## Next Steps for You

1. **Commit and Push** these changes to GitHub to build the new release APK.
2. Open the new APK on your phone. You will notice the "Add" buttons are locked.
3. Go to Settings, go through the payment flow, and tap "I Have Paid".
4. Go to the Admin Panel. You will now see your name with a "Requested" badge.
5. Tap the `+` icon and grant yourself 365 Days.
6. Go back to the Dashboard. The lock will disappear, and the "Add" buttons will return!

---

render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/services/ledger_service.dart)
render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/screens/admin_panel_screen.dart)
render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/screens/dashboard_screen.dart)
render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/screens/contact_detail_screen.dart)
