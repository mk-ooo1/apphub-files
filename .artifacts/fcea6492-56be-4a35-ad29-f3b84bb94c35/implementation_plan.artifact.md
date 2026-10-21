# Implementation Plan - Fix Missing Users in Admin Panel

This plan addresses the issue where only two users are showing in the Admin Panel, despite there being more registered users in Firebase. The core of the problem lies in the overly strict filtering in `LedgerService.watchAllUserProfiles()`.

## User Review Required

> [!IMPORTANT]
> Currently, the query specifically filters for documents containing an `email` field: `.where((d) => d.data().containsKey('email'))`. If an old user logged in before this logic was robust, their profile might just contain their name, or it might just exist as an empty document (acting as a parent for their transactions). I will remove this filter entirely to ensure *every* user document is displayed.

## Proposed Changes

### [MODIFY] `lib/services/ledger_service.dart`
- In `watchAllUserProfiles()`:
    - Remove the `.where((d) => d.data().containsKey('email'))` filter completely.
    - Instead, try to parse *every* document in the `users` collection using `UserProfile.fromMap`.
    - The `fromMap` factory already provides fallbacks (e.g., `email` defaults to `''`, `name` defaults to `'User'`), so no errors will occur even if the document is completely empty.

## Verification Plan

### Manual Verification
- Open the app, go to Settings -> Developer (7 taps), and open the Admin Panel.
- Navigate to the "Manage Users" tab.
- Verify that *all* users are now visible, including those that might have been missing previously. Users missing an email will simply display a blank email field.
