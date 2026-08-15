# Walkthrough - Transaction Direction Filtering

I have added filtering by "Gave" and "Got" directions to the transaction lists in both the Dashboard and the Contact Detail screens.

## Changes Made

### 1. Dashboard - Account Tab
- Added a filter button (list icon) next to the search bar.
- Users can now filter the "All Transactions" list by:
    - **All**: Shows everything.
    - **Gave**: Shows only outgoing transactions.
    - **Got**: Shows only incoming transactions.
- The filter works in combination with the existing search bar.

### 2. Contact Detail Screen
- Added the same filter functionality to the **Principal**, **Interest**, and **Bank Transactions** lists.
- For **Bank** accounts, the filter labels automatically adjust to **Withdraw** and **Deposit** for better clarity.
- For **Personal/Business** contacts, the labels remain **Gave** and **Got**.

### 3. Localization
- Added an `all` key to English, Hindi, and Marathi localization files to provide a translated "All" option in the filter menu.

## Verification

- [x] Verified that the filter correctly isolates "Gave" and "Got" transactions in the Dashboard.
- [x] Verified that the labels in the Contact Detail screen correctly change based on whether the contact is a bank.
- [x] Confirmed that searching and filtering can be used together seamlessly.
- [x] Confirmed that localization for the "All" option works in all supported languages.

---

render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/screens/dashboard_screen.dart)
render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/screens/contact_detail_screen.dart)
render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/l10n/app_en.arb)
render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/l10n/app_hi.arb)
render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/l10n/app_mr.arb)
