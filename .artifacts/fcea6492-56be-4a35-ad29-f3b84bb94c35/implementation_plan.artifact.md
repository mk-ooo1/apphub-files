# Implementation Plan - Fix Exact Alarm Permission Error

This plan resolves the `PlatformException(exact_alarms_not_permitted, ...)` error on Android 14+ by correctly checking and requesting the `SCHEDULE_EXACT_ALARM` permission and providing a fallback to inexact alarms if permission is denied.

## User Review Required

> [!IMPORTANT]
> On Android 14+, apps must have explicit user permission to schedule exact alarms. I will update the app to:
> 1.  Check for the permission automatically when a reminder is set.
> 2.  Request the permission (which opens system settings) if it's missing.
> 3.  Fallback to "inexact" alarms if the user refuses, so the reminder still works (though it might be a few minutes late).

## Proposed Changes

### Notification Service

#### [MODIFY] [notification_service.dart](file:///D:/FlutterProjects/money_manage_app/lib/services/notification_service.dart)
- Update `scheduleTransactionReminder` to:
    - Check `canScheduleExactAlarms()`.
    - If `false`, attempt to request the permission via `Permission.scheduleExactAlarm.request()`.
    - Determine the `AndroidScheduleMode` based on the final permission status:
        - `exactAllowWhileIdle` if permitted.
        - `inexactAllowWhileIdle` if not permitted.
- This ensures the app never crashes with `exact_alarms_not_permitted` and always schedules *some* form of reminder.

### UI Improvements (Optional but Recommended)

#### [MODIFY] [add_transaction_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/add_transaction_screen.dart)
- Improve the error handling in the `_save` method to provide a more helpful message if the reminder setup encounters issues.

## Verification Plan

### Manual Verification
- Test on an Android 14+ device.
- Try setting a reminder.
- Observe if the app requests the "Alarms & Reminders" permission.
- If permission is granted, verify the reminder is exact.
- If permission is denied, verify the reminder is still scheduled (using inexact mode) and no crash occurs.
