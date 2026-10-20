# Implementation Plan - Fix User Document Structure & Visibility

This plan addresses the core issue preventing users from appearing in the Admin Panel: user documents are being created with random auto-IDs instead of the user's Firebase UID.

## User Review Required

> [!IMPORTANT]
> The root cause of the "No users found" issue is that `watchAllUserProfiles()` looks for documents where the ID is the user's `UID`. If the documents are saved under random IDs (like `doc().set()`), they won't match the expected structure, and managing them (like granting premium) will fail because the app won't know which UID to update.
>
> We need to fix the registration flow to ensure users are explicitly saved with their Firebase UID as the document ID.

## Proposed Changes

### [MODIFY] `lib/services/ledger_service.dart`
- In `createUserProfile(User user)`, ensure we are explicitly using `doc(user.uid).set(...)`. This is already in the current code, but we must verify it.
- **The real issue**: If the user collection was somehow populated with random IDs in the past, those users won't map correctly. However, since the code currently uses `_db.collection('users').doc(user.uid)`, new logins *should* be correct.

### [MODIFY] `lib/screens/admin_panel_screen.dart`
- Let's display the Document ID in the subtitle as a debugging step to confirm if the IDs are random or actual UIDs.

### [MODIFY] `lib/screens/auth_screen.dart`
- Ensure `createUserProfile` is called correctly *every* time a user successfully signs in, so their document is created or updated with the correct UID.

## Verification Plan
1. Open the app and log in (or log out and log back in).
2. Go to the Admin Panel.
3. Verify that *your* user profile now appears.
4. If old data was under random IDs, it will need to be manually migrated or ignored, but all future logins will be correct.
