# Implementation Plan - Separate Bank Accounts & Contact Ledgers

The user wants to manage bank balances manually, similar to how they manage contacts. This involves creating "Bank" entities that have their own transactions, separate from "Personal/Business" contacts.

## User Review Required

> [!IMPORTANT]
> **Transaction Terminology**:
> - For **Contacts**: We use "You Gave" (Receivable) and "You Got" (Payable).
> - For **Banks**: I will update the labels to **"Deposit"** (Increases Bank Balance) and **"Withdraw"** (Decreases Bank Balance) to avoid confusion.
>
> **Global Balance**:
> - The main "Bank Balance" card will now show the **Sum of all Bank Accounts** you have created.
>
> Does this approach meet your needs?

## Proposed Changes

### 1. Data Model Updates
#### [MODIFY] [contact.dart](file:///D:/FlutterProjects/money_manage_app/lib/models/contact.dart)
- Add `bank` to `ContactMode` enum.

### 2. Localization Updates
#### [MODIFY] [app_en.arb](file:///D:/FlutterProjects/money_manage_app/lib/l10n/app_en.arb) (and hi/mr)
- Add keys: `bank`, `deposit`, `withdraw`, `bankName`, `totalBankBalance`.

### 3. Business Logic Updates
#### [MODIFY] [ledger_service.dart](file:///D:/FlutterProjects/money_manage_app/lib/services/ledger_service.dart)
- Update `calculateLiveBankBalance` to filter contacts by `mode == bank` and sum their `contactBalance`.

### 4. UI - Add Contact/Bank
#### [MODIFY] [add_contact_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/add_contact_screen.dart)
- Add "Bank" to the `SegmentedButton`.
- Update labels dynamically: if "Bank" is selected, show "Bank Name" instead of "Name".

### 5. UI - Dashboard Refactor
#### [MODIFY] [dashboard_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/dashboard_screen.dart)
- **Contacts Tab**: Show contacts with `mode == personal` or `business`.
- **Account Tab**:
  - Top: "Total Bank Balance" card (sum of all banks).
  - List: All entities with `mode == bank` (e.g., SBI, HDFC, Wallet).
  - Tapping a bank opens its specific transaction history.

### 6. UI - Transaction Labels
#### [MODIFY] [contact_detail_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/contact_detail_screen.dart)
#### [MODIFY] [add_transaction_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/add_transaction_screen.dart)
- Update FAB and Header labels:
  - If `contact.mode == bank`: Use "Deposit" / "Withdraw".
  - Otherwise: Use "You Gave" / "You Got".

## Verification Plan

### Manual Verification
1. Go to **Contacts** tab -> Add "John Doe" (Personal). Add transaction.
2. Go to **Account** tab -> Add "SBI Bank" (Bank mode).
3. Verify "John Doe" does **not** appear in the Account tab.
4. Verify "SBI Bank" does **not** appear in the Contacts tab.
5. In "SBI Bank", tap "Deposit" (₹5,000). Verify balance is ₹5,000.
6. Verify the "Total Bank Balance" card on the Account tab updates to show ₹5,000.
