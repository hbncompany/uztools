import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final starredCodes =
        prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
    final List<Map<String, dynamic>> notifications = [];
    for (var code in starredCodes) {
      final notificationData = prefs.getString('notification_$code');
      if (notificationData != null) {
        final data = jsonDecode(notificationData) as Map<String, dynamic>;
        notifications.add(data);
      }
    }
    notifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _clearNotification(String na2Code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_$na2Code');
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('notifications_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(12),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
            : _notifications.isEmpty
                ? Center(
                    child: Text(
                      Localization.translate('no_notifications'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: NotificationCard(
                          notification: notification,
                          onDismiss: () async {
                            await _clearNotification(
                                notification['na2_code'] as String);
                          },
                          onInfoPressed: () {
                            _showNotificationDetails(context, notification);
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _showNotificationDetails(
      BuildContext context, Map<String, dynamic> notification) {
    final String taxName = Localization.currentLanguage == 'ru'
        ? notification['tax_name_ru']?.toString() ?? ''
        : notification['tax_name_uz']?.toString() ?? '';
    final String na2Code = notification['na2_code']?.toString() ?? '';
    final String paymentDate = notification['payment_date']?.toString() ?? '';
    final String timestamp = notification['timestamp']?.toString() ?? '';
    final DateTime notifiedAt = DateTime.parse(timestamp);
    final String formattedNotifiedAt =
        '${notifiedAt.day.toString().padLeft(2, '0')}.${notifiedAt.month.toString().padLeft(2, '0')}.${notifiedAt.year} ${notifiedAt.hour.toString().padLeft(2, '0')}:${notifiedAt.minute.toString().padLeft(2, '0')}';

    // Calculate days until payment
    int daysUntil;
    try {
      final paymentDateParsed = DateTime.parse(paymentDate);
      final today = DateTime.now();
      final paymentDateOnly = DateTime(paymentDateParsed.year,
          paymentDateParsed.month, paymentDateParsed.day);
      final todayOnly = DateTime(today.year, today.month, today.day);
      daysUntil = paymentDateOnly.difference(todayOnly).inDays;
    } catch (e) {
      daysUntil = 0; // Fallback if date parsing fails
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Localization.translate('notification_details')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${Localization.translate('tax_name')}: $taxName',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '${Localization.translate('na2_code')}: $na2Code',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '${Localization.translate('payment_date')}: $paymentDate',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '${Localization.translate('days_until_payment')}: $daysUntil',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '${Localization.translate('notified_at')}: $formattedNotifiedAt',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(Localization.translate('close')),
            ),
          ],
        );
      },
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDismiss;
  final VoidCallback onInfoPressed;

  const NotificationCard({
    required this.notification,
    required this.onDismiss,
    required this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String taxName = Localization.currentLanguage == 'ru'
        ? notification['tax_name_ru']?.toString() ?? ''
        : notification['tax_name_uz']?.toString() ?? '';
    final String timestamp = notification['timestamp']?.toString() ?? '';
    final DateTime dateTime = DateTime.parse(timestamp);
    final String formattedTime =
        '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Localization.translate('tax_name')}: $taxName',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Localization.translate('payment_date')}: ${notification['payment_date']?.toString() ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Localization.translate('na2_code')}: ${notification['na2_code']?.toString() ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Localization.translate('notified_at')}: $formattedTime',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.info,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: onInfoPressed,
                  tooltip: Localization.translate('view_details'),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: onDismiss,
                  tooltip: Localization.translate('dismiss_notification'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
