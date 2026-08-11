# Walkthrough - Manual Bank Account Management

I have implemented a completely separate system for managing your Bank Accounts, allowing you to track your real money independently from what people owe you.

## Changes Made

### 1. New "Bank" Entity Type
- **Add Contact Screen**: You can now select **"Bank"** when adding a new entry.
- **Dynamic Labels**: When you create a Bank, the app asks for a **"Bank Name"** (like SBI or HDFC) and a **"Starting Bank Balance"**.

### 2. Dashboard Separation
- **Contacts Tab**: Now strictly shows people (Personal/Business contacts). Your banks are hidden from here to keep the list clean.
- **Account Tab**:
  - Shows your **"Total Bank Balance"** (the sum of all your bank accounts).
  - Lists all your added Bank accounts.
  - Tapping a bank opens its specific history.

### 3. Professional Banking Labels
- **Withdraw/Deposit**: When dealing with a Bank, the buttons automatically change from "You Gave/Got" to **"Withdraw"** and **"Deposit"**.
- **Clear Status**: The balance banner in a bank now says **"Current Bank Balance"** instead of "You will get".

### 4. Language & Math
- Updated English, Hindi, and Marathi translations for all banking terms.
- Refined the math engine to treat Bank accounts as positive assets.

## How to Test

### 1. Create a Bank Account
1. Open the app and go to the **Account** tab.
2. Tap the **+** button.
3. Select **Bank** from the top toggle.
4. Enter `SBI Bank` and a starting balance of `10,000`. Save it.

### 2. Record a Deposit/Withdrawal
1. Tap on `SBI Bank` in the Account list.
2. Notice the buttons are now **"Withdraw"** and **"Deposit"**.
3. Tap **Deposit** and add `5,000`.
4. Verify the SBI balance is now `15,000`.

### 3. Check Global Total
1. Go back to the **Account** tab main screen.
2. The big blue card should now show your **Total Bank Balance** as `₹15,000.00`.

### 4. Verify Separation
1. Go to the **Contacts** tab.
2. Verify that `SBI Bank` is **NOT** visible there.
3. Go back to the **Account** tab.
4. Verify your regular contacts (like "John Doe") are **NOT** visible there.
