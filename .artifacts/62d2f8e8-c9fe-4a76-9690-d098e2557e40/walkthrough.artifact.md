# Walkthrough - Transaction Locking & App PIN Security

I have implemented the "Lock/Unlock" feature with cumulative math logic and added a secure App PIN lock screen.

## Changes Made

### 1. Cumulative Transaction Locking
- **Model**: Added `isLocked` field to `LedgerTransaction`.
- **Logic**: Updated `LedgerService.contactBalance` to use cumulative math for locked transactions.
  - *Example*: Give 20,000 (Locked) + Got 5,000 (Locked) = **25,000 Total**.
- **UI**:
  - Added a "Lock Transaction" toggle in `AddTransactionScreen`.
  - Locked transactions show an orange lock icon in the history.
  - Locked transactions **cannot be edited or swiped-to-delete**, ensuring your cumulative totals are permanent.

### 2. App PIN Security
- **Security Service**: Created a service to securely store and verify an App PIN using `shared_preferences`.
- **Lock Screen**: A new PIN entry screen that blocks app access if a PIN is set.
- **Setup**: Added "Set App PIN" and "Clear App PIN" options to the main dashboard menu.

## How to Test

### Locking Feature
1. Open any contact.
2. Add a "You Gave" transaction for **20,000** and toggle **Lock Transaction** before saving.
3. Add a "You Got" transaction for **5,000** and toggle **Lock Transaction** before saving.
4. Verify the contact balance shows **₹25,000** instead of ₹15,000.
5. Notice that you cannot edit these transactions anymore (fields are disabled).

### PIN Lock Feature
1. On the Dashboard, tap the three-dots menu and select **Set App PIN**.
2. Enter a 4-digit PIN (e.g., `1234`) and save.
3. Close the app and restart it.
4. You should be greeted by the **Enter PIN** screen.
5. Enter your PIN to access the dashboard.
6. (Optional) Clear the PIN from the same menu to disable the lock.

> [!NOTE]
> If you forget your PIN, you will need to clear app data or reinstall the app, which will reset your local login (but your transactions are safe in Firestore).
