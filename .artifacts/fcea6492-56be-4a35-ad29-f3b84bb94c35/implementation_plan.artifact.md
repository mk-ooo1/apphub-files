# Implementation Plan - WhatsApp-Based Activation Requests

This plan simplifies the "Activation Request" flow by redirecting the user directly to the Admin's WhatsApp with a pre-filled message after payment, eliminating the need for complex in-app request states.

## Proposed Changes

### 1. Data Models
- **[NEW] `lib/models/subscription_plan.dart`**: Model for `id`, `name`, `days`, `price`.
- **[MODIFY] `lib/models/user_profile.dart`**:
    - Replace `isPremium` boolean with `premiumUntil` (DateTime).
    - Add helper: `bool get isPremiumActive => premiumUntil != null && premiumUntil!.isAfter(DateTime.now());`

### 2. Admin Configuration (`admin_service.dart`)
- **[MODIFY] `AdminConfig`**:
    - Add `upiId` (String).
    - Add `adminWhatsApp` (String) - e.g., "+919876543210".
    - Add `plans` (List<SubscriptionPlan>).

### 3. User Payment Flow (`settings_screen.dart`)
- When a user taps "Upgrade", display the available plans.
- After selecting a plan, show the specific UPI link and QR code.
- Add an **"I Have Paid (Send Details on WhatsApp)"** button.
- When tapped, use `url_launcher` to open WhatsApp targeting the `adminWhatsApp` number with a pre-filled message like: *"Hello, I have paid ₹[Price] for the [Plan Name] plan. My email is [User Email]. Please activate my account."*

### 4. Admin Panel UI (`admin_panel_screen.dart`)
- **Config Tab**: Edit `upiId`, `adminWhatsApp`, and manage the Subscription Plans list.
- **Users Tab**:
    - Display all users.
    - Show their expiration date.
    - Provide simple "+30 Days", "+365 Days", etc., buttons or a date picker to grant access manually after verifying the WhatsApp message.

### 5. Dependencies
- Add `qr_flutter` to `pubspec.yaml` for generating payment codes.

## Verification Plan
1. Admin configures plans and WhatsApp number.
2. User selects a plan, views the QR code, and taps the WhatsApp button.
3. Verify WhatsApp opens with the correct pre-filled message and target number.
4. Admin opens the "Manage Users" tab, finds the user's email, and adds the requested days.
5. User's app updates to show "Premium Active until [Date]".
