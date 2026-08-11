# Walkthrough - Interest Tracking Feature

I have implemented the ability to track "Interest" separately from "Principal" while maintaining the cumulative locked calculation you requested.

## Changes Made

### 1. Principal vs Interest Tracking
- **Transaction Type**: Every transaction now has a type: **Principal** or **Interest**.
- **Logic**: Updated the calculation engine to track these two categories separately.
  - *Scenario*: You give 20,000 (Principal) and receive 5,000 (Interest).
  - If both are locked, the total will show **₹25,000**.
  - The app now displays a breakdown: **Principal: ₹20,000** and **Interest: ₹5,000**.

### 2. UI Updates
- **Add Transaction**: New selector to choose between Principal and Interest.
- **Contact Details**:
  - The top banner now shows the **Principal** and **Interest** breakdown below the main total.
  - Transactions of type "Interest" now have a blue **INTEREST** badge in the list.

## How to Test

1. Open a contact's details.
2. Add a "You Gave" transaction of **₹20,000**, select **Principal**, and toggle **Lock**.
3. Add a "You Got" transaction of **₹5,000**, select **Interest**, and toggle **Lock**.
4. Observe the top banner:
   - Total: **₹25,000** (cumulative volume).
   - Principal: **₹20,000** (amount you gave).
   - Interest: **₹5,000** (amount they gave as interest).
5. Notice the blue **INTEREST** badge next to the 5,000 entry.

This ensures you can always see exactly what portion of the total is the original money and what portion is interest!
