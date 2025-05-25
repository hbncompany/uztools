import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uztools/notification_service.dart';
import 'localization.dart';

class SavedTaxesScreen extends StatefulWidget {
  const SavedTaxesScreen({Key? key}) : super(key: key);

  @override
  _SavedTaxesScreenState createState() => _SavedTaxesScreenState();
}

class _SavedTaxesScreenState extends State<SavedTaxesScreen> {
  List<Map<String, dynamic>> _savedTaxes = [];
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
    _loadSavedTaxes();
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

  Future<void> _loadSavedTaxes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final starredCodes =
          prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
      final List<Map<String, dynamic>> taxes = [];
      final seenCompositeKeys = <String>{};

      for (var code in starredCodes) {
        if (code.contains('_')) {
          final taxData = prefs.getString('tax_$code');
          if (taxData != null) {
            try {
              final data = jsonDecode(taxData) as Map<String, dynamic>;
              debugPrint(
                  'Loaded tax for $code: na2_code=${data['na2_code']}, payment_date=${data['payment_date']}');
              taxes.add(data);
              seenCompositeKeys.add(code);
            } catch (e) {
              debugPrint('Error decoding tax for $code: $e');
            }
          }
        } else {
          final na2Code = code;
          final allKeys = prefs
              .getKeys()
              .where((key) => key.startsWith('tax_${na2Code}_'))
              .toList();
          for (var key in allKeys) {
            final compositeKey = key.replaceFirst('tax_', '');
            if (seenCompositeKeys.contains(compositeKey)) continue;
            final taxData = prefs.getString(key);
            if (taxData != null) {
              try {
                final data = jsonDecode(taxData) as Map<String, dynamic>;
                debugPrint(
                    'Loaded tax for $compositeKey: na2_code=${data['na2_code']}, payment_date=${data['payment_date']}');
                taxes.add(data);
                seenCompositeKeys.add(compositeKey);
              } catch (e) {
                debugPrint('Error decoding tax for $key: $e');
              }
            }
          }
        }
      }

      taxes.sort((a, b) {
        final dateA = a['payment_date']?.toString() ?? '';
        final dateB = b['payment_date']?.toString() ?? '';
        return dateA.compareTo(dateB);
      });

      setState(() {
        _savedTaxes = taxes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _savedTaxes = [];
        _isLoading = false;
      });
      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Localization.translate('error_loading_taxes')),
            ),
          );
        }
      });
      debugPrint('Error loading saved taxes: $e');
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

  Future<void> _toggleStarredTax(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final starredCodes =
          prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
      final notificationService = NotificationService();

      debugPrint(
          'Initial starred_tax_codes: $starredCodes, attempting to unstar: $code');

      bool success = false;
      String? na2Code;
      String? compositeKey;

// Parse code
      if (code.contains('_')) {
        compositeKey = code;
        na2Code = code.split('_').first;
      } else {
        na2Code = code;
      }

      if (starredCodes.contains(compositeKey)) {
// Unstar single payment date
        starredCodes.remove(compositeKey);
        final removed = await prefs.remove('tax_$compositeKey');
        debugPrint(
            'Unstarred single tax: $compositeKey, tax_$compositeKey removed: $removed');
        success = true;
      } else if (starredCodes.contains(na2Code) && compositeKey != null) {
// Unstar specific date when na2_code is starred
        final removed = await prefs.remove('tax_$compositeKey');
        debugPrint(
            'Removed tax_$compositeKey for na2_code: $na2Code, success: $removed');

// Get remaining tax entries for na2_code
        final allKeys = prefs
            .getKeys()
            .where((key) => key.startsWith('tax_${na2Code}_'))
            .toList();
        if (allKeys.isEmpty) {
// No remaining dates, remove na2_code
          starredCodes.remove(na2Code);
          debugPrint(
              'No remaining tax entries for na2_code: $na2Code, removed from starred_tax_codes');
        } else {
// Replace na2_code with individual compositeKeys
          starredCodes.remove(na2Code);
          final newCompositeKeys =
              allKeys.map((key) => key.replaceFirst('tax_', '')).toSet();
          starredCodes.addAll(newCompositeKeys);
          debugPrint(
              'Replaced na2_code: $na2Code with compositeKeys: $newCompositeKeys');
        }
        success = true;
      } else if (starredCodes.contains(na2Code)) {
// Unstar all payment dates for na2_code
        starredCodes.remove(na2Code);
        final allKeys = prefs
            .getKeys()
            .where((key) => key.startsWith('tax_${na2Code}_'))
            .toList();
        if (allKeys.isEmpty) {
          debugPrint('No tax entries found for na2_code: $na2Code');
        }
        for (var key in allKeys) {
          final removed = await prefs.remove(key);
          debugPrint('Removed tax entry: $key, success: $removed');
        }
        debugPrint('Unstarred all taxes for na2_code: $na2Code');
        success = true;
      } else {
        debugPrint('Code not found in starred_tax_codes: $code');
      }

      if (success) {
// Save updated starred_tax_codes
        final saveSuccess = await prefs.setStringList(
            'starred_tax_codes', starredCodes.toList());
        debugPrint(
            'Saved starred_tax_codes: $starredCodes, success: $saveSuccess');

// Verify save
        final updatedCodes =
            prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
        debugPrint('Verified starred_tax_codes after save: $updatedCodes');

        await _loadSavedTaxes();
        await notificationService.init();
        await notificationService.checkAndSendTaxNotifications();
        setState(() {});
        _showInterstitialAd();
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(compositeKey != null && starredCodes.isNotEmpty
                    ? Localization.translate('tax_date_unstarred_success')
                    : Localization.translate('tax_unstarred_success')),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling starred tax: $e');
      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Localization.translate('error_toggling_tax')),
            ),
          );
        }
      });
    }
  }

  void _showTaxDetails(BuildContext context, Map<String, dynamic> tax) {
    final taxName = Localization.currentLanguage == 'ru'
        ? tax['tax_name_ru']?.toString() ?? Localization.translate('unknown')
        : tax['tax_name_uz']?.toString() ?? Localization.translate('unknown');
    final na2Code =
        tax['na2_code']?.toString() ?? Localization.translate('unknown');
    final paymentDate = tax['payment_date']?.toString() ?? '';
    final period = Localization.currentLanguage == 'ru'
        ? tax['period_ru']?.toString() ?? Localization.translate('unknown')
        : tax['period_uz']?.toString() ?? Localization.translate('unknown');
    final ynl = tax['YNL']?.toString() ?? Localization.translate('unknown');

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
          title: Text(Localization.translate('tax_details')),
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
                _buildDetailRow(
                    context,
                    Localization.translate('payment_date'),
                    paymentDate.isNotEmpty
                        ? paymentDate
                        : Localization.translate('unknown')),
                _buildDetailRow(
                    context,
                    Localization.translate('days_until_payment'),
                    daysUntilText),
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

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
    _isAdLoaded = false;
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
        title: Text(Localization.translate('saved_taxes_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
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
            : _savedTaxes.isEmpty
                ? Center(
                    child: Text(
                      Localization.translate('no_saved_taxes'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _savedTaxes.length,
                    itemBuilder: (context, index) {
                      final tax = _savedTaxes[index];
                      final na2Code = tax['na2_code']?.toString() ?? '';
                      final paymentDate = tax['payment_date']?.toString() ?? '';
                      final compositeKey = paymentDate.isNotEmpty
                          ? '${na2Code}_$paymentDate'
                          : na2Code;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SavedTaxCard(
                          tax: tax,
                          onStarToggled: () => _toggleStarredTax(compositeKey),
                          onInfoPressed: () => _showTaxDetails(context, tax),
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

class SavedTaxCard extends StatelessWidget {
  final Map<String, dynamic> tax;
  final VoidCallback onStarToggled;
  final VoidCallback onInfoPressed;

  const SavedTaxCard({
    Key? key,
    required this.tax,
    required this.onStarToggled,
    required this.onInfoPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taxName = Localization.currentLanguage == 'ru'
        ? tax['tax_name_ru']?.toString() ?? Localization.translate('unknown')
        : tax['tax_name_uz']?.toString() ?? Localization.translate('unknown');
    final period = Localization.currentLanguage == 'ru'
        ? tax['period_ru']?.toString() ?? Localization.translate('unknown')
        : tax['period_uz']?.toString() ?? Localization.translate('unknown');
    final na2Code =
        tax['na2_code']?.toString() ?? Localization.translate('unknown');
    final paymentDate =
        tax['payment_date']?.toString() ?? Localization.translate('unknown');
    final ynl = tax['YNL']?.toString() ?? Localization.translate('unknown');

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
                    '${Localization.translate('YNL')}: $ynl',
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
                  icon: const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onPressed: onStarToggled,
                  tooltip: Localization.translate('remove_from_saved'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
