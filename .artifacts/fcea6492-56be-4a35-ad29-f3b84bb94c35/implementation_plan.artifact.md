# Implementation Plan - Fix Compilation Syntax Errors

This plan resolves the compilation syntax errors in `dashboard_screen.dart` and the missing imports in both `dashboard_screen.dart` and `main.dart`.

## User Review Required

> [!IMPORTANT]
> The errors reported by GitHub Actions indicate missing imports and a malformed widget tree due to mismatched parentheses/brackets during the last series of code replacements.

## Proposed Changes

### [MODIFY] `lib/main.dart`
- Import `LedgerService` so the app can call `LedgerService().createUserProfile()`.

### [MODIFY] `lib/screens/dashboard_screen.dart`
- Import `UserProfile` so the `StreamBuilder` can recognize the type.
- Fix the bracket mismatch in the `showModalBottomSheet` builder inside the `FloatingActionButton`. A `SafeArea` was opened but the `showModalBottomSheet` builder was never closed properly in the previous replacements.

## Verification Plan

### Manual Verification
- The Dart analyzer should report zero errors in both files locally.
- Pushing to GitHub should result in a successful build.
