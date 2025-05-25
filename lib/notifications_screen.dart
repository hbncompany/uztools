import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uztools/notification_service.dart';
import 'localization.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isAdLoaded = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initializeAds();
    _loadNotifications();
    Future.delayed(const Duration(seconds: 2), _showInterstitialAd);
  }

  void _initializeAds() {
    try {
      MobileAds.instance.initialize();
      _loadBannerAd();
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('Error initializing ads: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final starredCodes =
          prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
      final List<Map<String, dynamic>> notifications = [];
      final seenCompositeKeys = <String>{};

      for (var code in starredCodes) {
        if (code.contains('_')) {
// Single notification
          final notificationData = prefs.getString('notification_$code');
          if (notificationData != null) {
            try {
              final data = jsonDecode(notificationData) as Map<String, dynamic>;
              debugPrint(
                  'Loaded notification for $code: na2_code=${data['na2_code']}, payment_date=${data['payment_date']}');
              notifications.add(data);
              seenCompositeKeys.add(code);
            } catch (e) {
              debugPrint('Error decoding notification for $code: $e');
            }
          }
        } else {
// All notifications for na2_code
          final na2Code = code;
          final allKeys = prefs
              .getKeys()
              .where((key) => key.startsWith('notification_${na2Code}_'))
              .toList();
          for (var key in allKeys) {
            final compositeKey = key.replaceFirst('notification_', '');
            if (seenCompositeKeys.contains(compositeKey)) continue;
            final notificationData = prefs.getString(key);
            if (notificationData != null) {
              try {
                final data =
                    jsonDecode(notificationData) as Map<String, dynamic>;
                debugPrint(
                    'Loaded notification for $compositeKey: na2_code=${data['na2_code']}, payment_date=${data['payment_date']}');
                notifications.add(data);
                seenCompositeKeys.add(compositeKey);
              } catch (e) {
                debugPrint('Error decoding notification for $key: $e');
              }
            }
          }
        }
      }

// Sort notifications by timestamp (newest first)
      notifications.sort((a, b) {
        final aTimestamp =
            DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(0);
        final bTimestamp =
            DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(0);
        return bTimestamp.compareTo(aTimestamp);
      });

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(Localization.translate('error_loading_notifications')),
            ),
          );
        }
      });
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _clearNotification(String compositeKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final removed = await prefs.remove('notification_$compositeKey');
      debugPrint('Cleared notification_$compositeKey, success: $removed');
      if (removed) {
        await _loadNotifications();
        _showInterstitialAd();
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    Localization.translate('notification_cleared_success')),
              ),
            );
          }
        });
      } else {
        debugPrint('Notification not found: notification_$compositeKey');
      }
    } catch (e) {
      debugPrint('Error clearing notification: $e');
      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(Localization.translate('error_clearing_notification')),
            ),
          );
        }
      });
    }
  }

  void _loadBannerAd() {
    try {
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-7480088562684396/3085989451',
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            ad.dispose();
            setState(() {
              _isAdLoaded = false;
              _bannerAd = null;
            });
          },
        ),
      );
      _bannerAd?.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      setState(() {
        _isAdLoaded = false;
        _bannerAd = null;
      });
    }
  }

  void _loadInterstitialAd() {
    debugPrint('Loading interstitial ad');
    try {
      InterstitialAd.load(
        adUnitId: 'ca-app-pub-7480088562684396/8494399235',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded');
            setState(() {
              _interstitialAd = ad;
              _numInterstitialLoadAttempts = 0;
            });
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('Interstitial ad displayed');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Interstitial ad dismissed');
                ad.dispose();
                setState(() {
                  _interstitialAd = null;
                });
                _loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial ad failed to show: $error');
                ad.dispose();
                setState(() {
                  _interstitialAd = null;
                });
                _loadInterstitialAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
            setState(() {
              _numInterstitialLoadAttempts += 1;
              _interstitialAd = null;
            });
            if (_numInterstitialLoadAttempts < _maxFailedLoadAttempts) {
              _loadInterstitialAd();
            } else {
              Future.microtask(() {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        Localization.translate('interstitial_ad_load_error')
                            .replaceAll('{error}', error.message),
                      ),
                    ),
                  );
                }
              });
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
    }
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      debugPrint('Showing interstitial ad');
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial ad not loaded');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
    _isAdLoaded = false;
  }

  Future<void> _refreshNotifications() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Localization.translate('confirm_refresh')),
        content: Text(Localization.translate('confirm_refresh_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Localization.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(Localization.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final starredCodes =
          prefs.getStringList('starred_tax_codes')?.toSet() ?? {};

// Clear existing notifications
      for (var code in starredCodes) {
        final notificationKeys = prefs
            .getKeys()
            .where((key) => key.startsWith('notification_${code}_'))
            .toList();
        for (var key in notificationKeys) {
          await prefs.remove(key);
          debugPrint('Removed $key');
        }
        await prefs.remove('notification_sent_$code');
      }

// Clear active notifications
      await NotificationService().cancelAllNotifications();

// Reset UI
      setState(() {
        _notifications = [];
      });

// Re-evaluate notifications
      await NotificationService().checkAndSendTaxNotifications();

// Reload notifications
      await _loadNotifications();

      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  Localization.translate('notifications_refreshed_success')),
            ),
          );
        }
      });
      _showInterstitialAd();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  Localization.translate('error_refreshing_notifications')),
            ),
          );
        }
      });
      debugPrint('Error refreshing notifications: $e');
    }
  }

  void _showNotificationDetails(
      BuildContext context, Map<String, dynamic> notification) {
    final taxName = Localization.currentLanguage == 'ru'
        ? notification['tax_name_ru']?.toString() ??
            Localization.translate('unknown')
        : notification['tax_name_uz']?.toString() ??
            Localization.translate('unknown');
    final na2Code = notification['na2_code']?.toString() ??
        Localization.translate('unknown');
    final paymentDate = notification['payment_date']?.toString() ??
        Localization.translate('unknown');
    final period = Localization.currentLanguage == 'ru'
        ? notification['period_ru']?.toString() ??
            Localization.translate('unknown')
        : notification['period_uz']?.toString() ??
            Localization.translate('unknown');
    final ynl =
        notification['YNL']?.toString() ?? Localization.translate('unknown');
    final timestamp = notification['timestamp']?.toString() ?? '';
    final dateFormat = Localization.currentLanguage == 'ru'
        ? 'dd.MM.yyyy HH:mm'
        : 'yyyy-MM-dd HH:mm';
    final formattedNotifiedAt = timestamp.isNotEmpty
        ? DateFormat(dateFormat).format(DateTime.parse(timestamp))
        : Localization.translate('unknown');

    String daysUntilText = Localization.translate('unknown_date');
    if (paymentDate.isNotEmpty) {
      try {
        final paymentDateParsed = DateTime.parse(paymentDate);
        final today = DateTime.now();
        final paymentDateOnly = DateTime(paymentDateParsed.year,
            paymentDateParsed.month, paymentDateParsed.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        final daysUntil = paymentDateOnly.difference(todayOnly).inDays;
        final key = daysUntil >= 0
            ? (daysUntil == 1 ? 'days_until_one' : 'days_until')
            : (daysUntil == -1 ? 'payment_overdue_one' : 'payment_overdue');
        daysUntilText = Localization.translate(key)
            .replaceAll('{days}', daysUntil.abs().toString());
      } catch (e) {
        debugPrint('Error parsing payment date: $e');
        daysUntilText = Localization.translate('invalid_date');
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Localization.translate('notification_details')),
          contentPadding: const EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                    context, Localization.translate('tax_name'), taxName),
                _buildDetailRow(
                    context, Localization.translate('na2_code'), na2Code),
                _buildDetailRow(context, Localization.translate('YNL'), ynl),
                _buildDetailRow(
                    context, Localization.translate('period'), period),
                _buildDetailRow(context, Localization.translate('payment_date'),
                    paymentDate),
                _buildDetailRow(
                    context,
                    Localization.translate('days_until_payment'),
                    daysUntilText),
                _buildDetailRow(context, Localization.translate('notified_at'),
                    formattedNotifiedAt),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Localization.translate('close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
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
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
            tooltip: Localization.translate('refresh_notifications'),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(12),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Localization.translate('loading'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
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
                      final na2Code =
                          notification['na2_code']?.toString() ?? '';
                      final paymentDate =
                          notification['payment_date']?.toString() ?? '';
                      final compositeKey = paymentDate.isNotEmpty
                          ? '${na2Code}_$paymentDate'
                          : na2Code;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: NotificationCard(
                          notification: notification,
                          onDismiss: () => _clearNotification(compositeKey),
                          onInfoPressed: () =>
                              _showNotificationDetails(context, notification),
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? Container(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox.shrink(),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDismiss;
  final VoidCallback onInfoPressed;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onDismiss,
    required this.onInfoPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taxName = Localization.currentLanguage == 'ru'
        ? notification['tax_name_ru']?.toString() ??
            Localization.translate('unknown')
        : notification['tax_name_uz']?.toString() ??
            Localization.translate('unknown');
    final period = Localization.currentLanguage == 'ru'
        ? notification['period_ru']?.toString() ??
            Localization.translate('unknown')
        : notification['period_uz']?.toString() ??
            Localization.translate('unknown');
    final na2Code = notification['na2_code']?.toString() ??
        Localization.translate('unknown');
    final paymentDate = notification['payment_date']?.toString() ??
        Localization.translate('unknown');
    final timestamp = notification['timestamp']?.toString() ?? '';
    final dateFormat = Localization.currentLanguage == 'ru'
        ? 'dd.MM.yyyy HH:mm'
        : 'yyyy-MM-dd HH:mm';
    final formattedTime = timestamp.isNotEmpty
        ? DateFormat(dateFormat).format(DateTime.parse(timestamp))
        : Localization.translate('unknown');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 8),
                  Text(
                    '${Localization.translate('payment_date')}: $paymentDate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Localization.translate('na2_code')}: $na2Code',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Localization.translate('period')}: $period',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
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
