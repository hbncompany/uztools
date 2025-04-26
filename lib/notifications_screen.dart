import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';
import 'notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uztools/main.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  bool _isAdLoaded = false;
  BannerAd? _bannerAd;
  bool _isLoadingad = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadBannerAd();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final starredCodes = prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
      final List<Map<String, dynamic>> notifications = [];

      for (var compositeKey in starredCodes) {
        final notificationData = prefs.getString('notification_$compositeKey');
        if (notificationData != null) {
          try {
            final data = jsonDecode(notificationData) as Map<String, dynamic>;
            // Debug: Log na2_code to verify
            debugPrint('Notification na2_code for $compositeKey: ${data['na2_code']}');
            notifications.add(data);
          } catch (e) {
            debugPrint('Error decoding notification for $compositeKey: $e');
          }
        }
      }

      // Sort notifications by timestamp (newest first)
      notifications.sort((a, b) {
        final aTimestamp = a['timestamp']?.toString() ?? '';
        final bTimestamp = b['timestamp']?.toString() ?? '';
        return bTimestamp.compareTo(aTimestamp);
      });

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Localization.translate('error_loading_notifications')),
          ),
        );
      });
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _clearNotification(String compositeKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_$compositeKey');
      await _loadNotifications();
    } catch (e) {
      debugPrint('Error clearing notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate('error_clearing_notification')),
        ),
      );
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7480088562684396/3085989451', // Replace with actual ad unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
            _bannerAd = null;
          });
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    NotificationService().checkAndSendTaxNotifications();
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final starredCodes = prefs.getStringList('starred_tax_codes')?.toSet() ?? {};

    // Clear existing notifications from shared_preferences
    for (var code in starredCodes) {
      await prefs.remove('notification_$code');
      await prefs.remove('notification_sent_$code');
    }

    // Clear active notifications in the notification tray
    // final notificationsPlugin = NotificationService()._notificationsPlugin;
    // await notificationsPlugin.cancelAll();

    // Reset the UI
    setState(() {
      _notifications = [];
    });

    // Re-evaluate and send new notifications
    await NotificationService().checkAndSendTaxNotifications();

    // Reload notifications to update the UI
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('notifications_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshNotifications,
            tooltip: Localization.translate('refresh_notifications'),
          ),
        ],
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
                      final compositeKey =
                          '${notification['na2_code']}_${notification['payment_date']}';
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: NotificationCard(
                          notification: notification,
                          onDismiss: () async {
                            await _clearNotification(compositeKey);
                          },
                          onInfoPressed: () {
                            _showNotificationDetails(context, notification);
                          },
                        ),
                      );
                    },
                  ),
      ),bottomNavigationBar: BottomAppBar(
      child: Container(
        child: _isAdLoaded && _bannerAd != null
            ? SizedBox(
          height: _bannerAd!.size.height.toDouble(),
          width: _bannerAd!.size.width.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        )
            : const SizedBox.shrink(),
      ),
    ),
    );
  }

  void _showNotificationDetails(
      BuildContext context, Map<String, dynamic> notification) {
    final String taxName = Localization.currentLanguage == 'ru'
        ? notification['tax_name_ru']?.toString() ?? ''
        : notification['tax_name_uz']?.toString() ?? '';
    final String rawNa2Code = notification['na2_code']?.toString() ?? '';
    final String na2Code = rawNa2Code.contains('_')
        ? rawNa2Code.split('_').first
        : rawNa2Code;
    final String paymentDate = notification['payment_date']?.toString() ?? '';
    final String timestamp = notification['timestamp']?.toString() ?? '';
    final String ynl = notification['ynl']?.toString() ?? '';
    final String period = Localization.currentLanguage == 'ru'
        ? notification['period_ru']?.toString() ?? ''
        : notification['period_uz']?.toString() ?? '';
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
    final String rawNa2Code = notification['na2_code']?.toString() ?? '';
    final String period = notification['period']?.toString() ?? '';
    final String periods = Localization.currentLanguage == 'ru'
        ? notification['period_uz']?.toString() ?? ''
        : notification['period_uz']?.toString() ?? '';
    final String na2Code = rawNa2Code.contains('_')
        ? rawNa2Code.split('_').first
        : rawNa2Code;
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
                    '${Localization.translate('na2_code')}: $na2Code',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Localization.translate('period')}: $periods',
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
