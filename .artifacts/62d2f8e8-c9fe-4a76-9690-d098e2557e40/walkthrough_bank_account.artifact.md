# Walkthrough - Bank Account Balance & Unified Transaction List

I have implemented a dedicated "Account" management system that tracks your live bank balance and provides a unified view of every transaction in the app.

## Changes Made

### 1. Multi-Tab Dashboard
- **UI**: Added a `TabBar` to the main screen.
- **Tabs**:
  - **Contacts**: Your existing list of people and net balances.
  - **Account**: The new banking and unified transaction hub.

### 2. Live Bank Balance Tracking
- **Initial Amount**: You can now set your starting bank balance (e.g., 50,000).
- **Auto-Sync**: Every time you add a transaction:
  - **Got money**: Your bank balance **increases** automatically.
  - **Gave money**: Your bank balance **decreases** automatically.
- **Persistence**: Your base balance is saved securely on your phone.

### 3. Unified Transaction List
- **Global History**: In the "Account" tab, you now have a single, scrollable list of **every transaction** from **every contact**.
- **Visual Cues**:
  - Green arrows for incoming money (+).
  - Red arrows for outgoing money (-).
  - "INT" badges for interest-only records.
  - Contact names are clearly displayed next to each amount.

### 4. Multi-Language Support
- Added translation keys for all new account features in **English, Hindi, and Marathi**.

## How to Test

### Setting up your Bank Balance
1. Open the app and tap the **"Account"** tab at the top.
2. Tap the **"Update Base Balance"** button on the blue card.
3. Enter your current bank balance (e.g., `10,000`) and tap **Save**.
4. Verify the card now shows **₹10,000.00**.

### testing Auto-Update
1. Go to any contact.
2. Add a **"You Got"** transaction of **₹2,000**.
3. Go back to the **Account** tab.
4. Verify your balance is now **₹12,000**.
5. Add a **"You Gave"** transaction of **₹500**.
6. Verify your balance is now **₹11,500**.

### Checking the Unified List
1. Scroll down in the **Account** tab.
2. Verify you can see all your transactions (from different contacts) in a single list, sorted by date.
