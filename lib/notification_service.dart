import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('app_icon');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(settings);

    // Request permissions for Android 13+ and iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> checkAndSendTaxNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final starredCodes =
        prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var code in starredCodes) {
      final taxDataString = prefs.getString('tax_$code');
      if (taxDataString == null) continue;
      final taxData = jsonDecode(taxDataString) as Map<String, dynamic>;
      final paymentDateStr = taxData['payment_date']?.toString() ?? '';
      if (paymentDateStr.isEmpty) continue;

      try {
        final paymentDate = DateTime.parse(paymentDateStr);
        final paymentDateOnly =
            DateTime(paymentDate.year, paymentDate.month, paymentDate.day);
        final daysUntil = paymentDateOnly.difference(today).inDays;

        // Check if payment date is within 4 days and not past
        if (daysUntil >= 0 && daysUntil <= 7) {
          final taxName = taxData['tax_name_ru']?.toString() ??
              taxData['tax_name_uz']?.toString() ??
              'Tax';
          final notificationId = code.hashCode; // Unique ID per na2_code
          final lastSentKey = 'notification_sent_$code';
          final lastSentStr = prefs.getString(lastSentKey);

          // Check if notification was already sent today
          bool shouldSend = true;
          if (lastSentStr != null) {
            final lastSent = DateTime.parse(lastSentStr);
            if (lastSent.year == now.year &&
                lastSent.month == now.month &&
                lastSent.day == now.day) {
              shouldSend = false;
            }
          }

          if (shouldSend) {
            await _notificationsPlugin.show(
              notificationId,
              'Tax Payment Reminder',
              '$taxName (Code: $code) is due on $paymentDateStr',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'tax_reminders',
                  'Tax Payment Reminders',
                  channelDescription: 'Reminders for upcoming tax payments',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(),
              ),
            );

            // Save notification data
            final notificationData = {
              'na2_code': code,
              'tax_name_uz': taxData['tax_name_uz']?.toString() ?? '',
              'tax_name_ru': taxData['tax_name_ru']?.toString() ?? '',
              'payment_date': paymentDateStr,
              'timestamp': now.toIso8601String(),
            };
            await prefs.setString(
                'notification_$code', jsonEncode(notificationData));

            // Mark as sent today
            await prefs.setString(lastSentKey, now.toIso8601String());
          }
        }
      } catch (e) {
        // Handle invalid date format
        continue;
      }
    }
  }
}
