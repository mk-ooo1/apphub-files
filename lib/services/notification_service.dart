import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import '../models/ledger_transaction.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  Completer<void>? _initCompleter;

  Future<void> init({String timeZoneName = 'Asia/Kolkata'}) async {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();

    try {
      tzdata.initializeTimeZones();
      // Use user-defined or default timezone
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // CHANGED: Using a vector icon in the 'drawable' folder (ic_notification)
      const androidInit = AndroidInitializationSettings('ic_notification');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Explicitly request permissions for Android 13+
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
      
      _initCompleter!.complete();
    } catch (e) {
      debugPrint('Notification init error: $e');
      _initCompleter!.complete();
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await Permission.scheduleExactAlarm.isGranted;
    }
    return true;
  }

  Future<void> scheduleTransactionReminder({
    required String txnId,
    required String contactName,
    required double amount,
    required TxnDirection direction,
    required DateTime dateTime,
    ReminderRepeat repeat = ReminderRepeat.none,
  }) async {
    await init();
    
    // Check and request exact alarm permission for Android 14+
    bool useExact = true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        // Attempt to request, but don't block if it fails or requires manual settings
        final result = await Permission.scheduleExactAlarm.request();
        useExact = result.isGranted;
      } else {
        useExact = status.isGranted;
      }
    }

    final scheduleMode = useExact 
        ? AndroidScheduleMode.exactAllowWhileIdle 
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // SAFE ID: hashCode can be negative, which crashes Android notifications.
    // .abs() ensures it's always positive.
    final int id = (txnId.hashCode).abs();
    
    final verb = direction == TxnDirection.gave ? 'collect from' : 'pay';
    final title = 'Payment Reminder: $contactName';
    final body = 'Time to $verb $contactName: ₹${amount.toStringAsFixed(2)}';

    DateTime scheduledDate = dateTime;
    final now = DateTime.now();

    // Past date handling with 10s grace
    if (scheduledDate.isBefore(now)) {
      if (scheduledDate.isAfter(now.subtract(const Duration(seconds: 10)))) {
        scheduledDate = now.add(const Duration(seconds: 5));
      } else if (repeat == ReminderRepeat.none) {
        return; // Too far in past
      }
      
      if (repeat != ReminderRepeat.none) {
        while (scheduledDate.isBefore(now)) {
          if (repeat == ReminderRepeat.daily) scheduledDate = scheduledDate.add(const Duration(days: 1));
          if (repeat == ReminderRepeat.weekly) scheduledDate = scheduledDate.add(const Duration(days: 7));
          if (repeat == ReminderRepeat.monthly) {
            scheduledDate = DateTime(scheduledDate.year, scheduledDate.month + 1, scheduledDate.day, scheduledDate.hour, scheduledDate.minute);
          }
        }
      }
    }

    DateTimeComponents? matchComponents;
    if (repeat == ReminderRepeat.daily) matchComponents = DateTimeComponents.time;
    if (repeat == ReminderRepeat.weekly) matchComponents = DateTimeComponents.dayOfWeekAndTime;
    
    // Schedule Main Reminder
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _details(),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
      payload: txnId,
    );

    // Immediate confirmation using default system sound
    await _plugin.show(
      id + 1000000, // Large offset to avoid collision
      'Reminder Set Successfully',
      'Alert scheduled for: $contactName',
      _details(),
      payload: 'verified',
    );

    // 30-min Advance Reminder
    if (repeat == ReminderRepeat.none) {
      final advanceTime = scheduledDate.subtract(const Duration(minutes: 30));
      if (advanceTime.isAfter(now)) {
        await _plugin.zonedSchedule(
          id + 2000000, // Another distinct ID
          'Upcoming: $title',
          'In 30 minutes: $body',
          tz.TZDateTime.from(advanceTime, tz.local),
          _details(),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'money_manage_reminders_final_v6', // Updated to v6 to apply custom sound
        'Money Reminders',
        channelDescription: 'Reminders for money to give or collect',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        playSound: true,
        // CHANGED: Restoring custom sound 'reminder' from res/raw
        sound: RawResourceAndroidNotificationSound('reminder'),
        // CHANGED: Using 'ic_notification' which is explicitly in the keep.xml
        icon: 'ic_notification',
      ),
      iOS: DarwinNotificationDetails(
        sound: 'reminder.wav',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> cancelReminder(int id) async {
    await init();
    final safeId = id.abs();
    await _plugin.cancel(safeId);
    await _plugin.cancel(safeId + 1000000);
    await _plugin.cancel(safeId + 2000000);
  }
}
