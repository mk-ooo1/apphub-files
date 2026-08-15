# Implementation Plan - Transaction Direction Filtering

This plan adds filtering by "Gave" and "Got" directions to the transaction lists in the Dashboard and Contact Detail screens.

## Proposed Changes

### Dashboard Screen

#### [MODIFY] [dashboard_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/dashboard_screen.dart)
- Update `_AccountTabState` to include `TxnDirection? _directionFilter`.
- In the `build` method of `_AccountTabState`, add a `Row` containing the search `TextField` and a new `PopupMenuButton` for filtering by direction.
- Update the filtering logic in the `StreamBuilder` to filter by `_directionFilter`.

### Contact Detail Screen

#### [MODIFY] [contact_detail_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/contact_detail_screen.dart)
- Update `_TransactionListViewState` to include `TxnDirection? _directionFilter`.
- Add a `PopupMenuButton` next to the search `TextField`.
- Update the filtering logic to include `_directionFilter`.

### Localization

#### [MODIFY] [app_en.arb](file:///D:/FlutterProjects/money_manage_app/lib/l10n/app_en.arb)
#### [MODIFY] [app_hi.arb](file:///D:/FlutterProjects/money_manage_app/lib/l10n/app_hi.arb)
#### [MODIFY] [app_mr.arb](file:///D:/FlutterProjects/money_manage_app/lib/l10n/app_mr.arb)
- Add generic filter strings: `filterAll`, `filterGave`, `filterGot` (or reuse existing if appropriate). Given the context, reusing `allTransactions`, `gave`, and `got` might be sufficient, but dedicated "Filter" labels are cleaner.

## Verification Plan

### Manual Verification
- Open the Dashboard's **Account** tab. Use the filter to show only "Gave" or "Got" transactions. Combine with search to verify both work together.
- Open a **Contact Detail** screen. Test the filter in the Principal/Interest tabs and the Bank list.
- Verify that switching tabs or closing the screen resets or maintains state as expected.
