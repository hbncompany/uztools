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
    print('Initializing notifications with app_icon');
    try {
      await _notificationsPlugin.initialize(settings);
      print('Notification initialization successful');
    } catch (e) {
      print('Notification initialization failed: $e');
      rethrow;
    }
  }

  Future<void> checkAndSendTaxNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final starredCodes =
        prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var compositeKey in starredCodes) {
      final taxDataString = prefs.getString('tax_$compositeKey');
      if (taxDataString == null) continue;
      final taxData = jsonDecode(taxDataString) as Map<String, dynamic>;
      final na2Code = taxData['na2_code']?.toString() ?? '';
      final paymentDateStr = taxData['payment_date']?.toString() ?? '';
      if (paymentDateStr.isEmpty) continue;

      // Debug: Log na2Code and compositeKey
      print('NotificationService: na2Code: $na2Code, compositeKey: $compositeKey');

      try {
        final paymentDate = DateTime.parse(paymentDateStr);
        final paymentDateOnly =
        DateTime(paymentDate.year, paymentDate.month, paymentDate.day);
        final daysUntil = paymentDateOnly.difference(today).inDays;

        // Check if payment date is within 7 days and not past
        if (daysUntil >= 0 && daysUntil <= 7) {
          final taxName = taxData['tax_name_uz']?.toString() ??
              taxData['tax_name_ru']?.toString() ??
              'Tax';
          final notificationId = compositeKey.hashCode; // Unique ID per composite key
          final lastSentKey = 'notification_sent_$compositeKey';
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
              'UzTaxTools',
              '$taxName (Code: $na2Code) is due on $paymentDateStr',
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
              'na2_code': na2Code, // Store actual na2_code, not compositeKey
              'tax_name_uz': taxData['tax_name_uz']?.toString() ?? '',
              'tax_name_ru': taxData['tax_name_ru']?.toString() ?? '',
              'payment_date': paymentDateStr,
              'period_uz': taxData['period_uz']?.toString() ?? '',
              'PERIOD_RU': taxData['PERIOD_RU']?.toString() ?? '',
              'timestamp': now.toIso8601String(),
            };
            await prefs.setString(
                'notification_$compositeKey', jsonEncode(notificationData));

            // Mark as sent today
            await prefs.setString(lastSentKey, now.toIso8601String());

            // Debug: Log notification details
            print('Sent notification: ID=$notificationId, na2Code=$na2Code, compositeKey=$compositeKey');
          }
        }
      } catch (e) {
        print('Error processing tax for $compositeKey: $e');
        continue;
      }
    }
  }

  // Add method to clear all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      print('All notifications cleared');
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}