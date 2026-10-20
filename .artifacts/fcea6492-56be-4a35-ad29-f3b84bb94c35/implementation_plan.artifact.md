# Implementation Plan - Restrict Free Users & Fix Admin Visibility

This plan modifies the app to enforce a strict Premium-only model for creating data, refines the "Request Access" flow, and fixes the Admin Panel to properly display user profiles.

## User Review Required

> [!IMPORTANT]
> **Admin Panel Empty Issue**: The "No users found" issue is because older user profiles might not have the `isPremium` field, and my previous code was strictly filtering for it. I will fix the filter to show *all* users.
> **Strict Paywall**: Free users will still be able to *see* their old data, but the "Add Contact" and "Add Transaction" buttons will be hidden or disabled until you activate them.

## Proposed Changes

### 1. Fix Admin User List
- **[MODIFY] `lib/services/ledger_service.dart`**: Update `watchAllUserProfiles()` to simply map all documents in the `users` collection, removing the restrictive `.where` filter that was hiding older accounts.

### 2. Enhance Activation Requests
- **[MODIFY] `lib/models/user_profile.dart`**: Add a `String? pendingRequestPlan` field.
- **[MODIFY] `lib/services/ledger_service.dart`**: Add a method `requestActivation(String uid, String planName)` that updates this field.
- **[MODIFY] `lib/screens/settings_screen.dart`**: Update the "I Have Paid" button to call `requestActivation()` in addition to opening WhatsApp.
- **[MODIFY] `lib/screens/admin_panel_screen.dart`**: Update the user list UI to clearly highlight users who have a `pendingRequestPlan`.

### 3. Implement Strict Paywall
- **[MODIFY] `lib/screens/dashboard_screen.dart`**:
    - Wrap the Floating Action Buttons (`+ Add Contact`, `Split Bill`) in a check for `isPremiumActive`. If not premium, replace the buttons with an "Upgrade to Add Data" prompt, or hide them entirely.
- **[MODIFY] `lib/screens/contact_detail_screen.dart`**:
    - Hide the `Gave` and `Got` Floating Action Buttons if the user is not premium.

## Verification Plan
1. Open the app as a free user. Verify that "Add Contact" and "Add Transaction" buttons are absent or disabled.
2. Go to Settings, tap "Upgrade", select a plan, and tap "I Have Paid".
3. Log in as Admin. Verify the "Manage Users" tab now lists users.
4. Verify the user who requested activation has a "Pending: [Plan Name]" badge.
5. Grant the user +30 days. Verify the user can now add contacts and transactions.
