import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  final int _maxFailedLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    _loadSavedTaxes();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  Future<void> _loadSavedTaxes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final starredCodes = prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
      final List<Map<String, dynamic>> taxes = [];

      for (var compositeKey in starredCodes) {
        final taxData = prefs.getString('tax_$compositeKey');
        if (taxData != null) {
          try {
            final data = jsonDecode(taxData) as Map<String, dynamic>;
            // Debug: Log na2_code to verify
            debugPrint('Saved tax na2_code for $compositeKey: ${data['na2_code']}');
            taxes.add(data);
          } catch (e) {
            debugPrint('Error decoding tax for $compositeKey: $e');
          }
        }
      }

      setState(() {
        _savedTaxes = taxes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Localization.translate('error_loading_taxes')),
          ),
        );
      });
      debugPrint('Error loading saved taxes: $e');
    }
  }

  void _loadBannerAd() {
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

  void _loadInterstitialAd() {
    print("_loadInterstitialAd");
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-7480088562684396/8494399235',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            print("_interstitialAd LOADED");
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
          });
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print("_interstitialAd DISPLAYED");},
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              setState(() {
                _interstitialAd = null;
              });
              _loadInterstitialAd(); // Preload the next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print("onAdFailedToShowFullScreenContent");
              ad.dispose();
              setState(() {
                _interstitialAd = null;
              });
              _loadInterstitialAd(); // Try loading again
            },
          );
        },
        onAdFailedToLoad: (error) {
          print("_loadInterstitialAd ERROR");
          setState(() {
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
          });
          if (_numInterstitialLoadAttempts < _maxFailedLoadAttempts) {
            _loadInterstitialAd(); // Retry loading
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Localization.translate("interstitial_ad_load_error").replaceAll("{error}", error.message),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    }
  }

  Future<void> _toggleStarredTax(String compositeKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final starredCodes = prefs.getStringList('starred_tax_codes')?.toSet() ?? {};

      if (starredCodes.contains(compositeKey)) {
        starredCodes.remove(compositeKey);
        await prefs.remove('tax_$compositeKey');
        await prefs.setStringList('starred_tax_codes', starredCodes.toList());
        await _loadSavedTaxes(); // Refresh list
      }
    } catch (e) {
      debugPrint('Error toggling starred tax: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate('error_toggling_tax')),
        ),
      );
    }
  }

  void _showTaxDetails(BuildContext context, Map<String, dynamic> tax) {
    final String taxName = Localization.currentLanguage == 'ru'
        ? tax['tax_name_ru']?.toString() ?? ''
        : tax['tax_name_uz']?.toString() ?? '';
    final String rawNa2Code = tax['na2_code']?.toString() ?? '';
    final String na2Code = rawNa2Code.contains('_')
        ? rawNa2Code.split('_').first
        : rawNa2Code;
    final String paymentDate = tax['payment_date']?.toString() ?? '';
    final String period = Localization.currentLanguage == 'ru'
        ? tax['period_uz']?.toString() ?? ''
        : tax['period_uz']?.toString() ?? '';
    final String ynl = tax['ynl']?.toString() ?? '';

    // Debug: Log na2Code to verify
    debugPrint('Showing tax details, na2Code: $na2Code');

    // Calculate days until payment
    String daysUntilText = Localization.translate('unknown_date');
    if (paymentDate.isNotEmpty) {
      try {
        final paymentDateParsed = DateTime.parse(paymentDate);
        final today = DateTime.now();
        final paymentDateOnly = DateTime(
            paymentDateParsed.year, paymentDateParsed.month, paymentDateParsed.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        final daysUntil = paymentDateOnly.difference(todayOnly).inDays;
        daysUntilText = daysUntil >= 0
            ? Localization.translate('$daysUntil')
            .replaceAll('{days}', daysUntil.toString())
            : Localization.translate('payment_overdue')
            .replaceAll('{days}', (-daysUntil).toString());
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
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  context,
                  Localization.translate('tax_name'),
                  taxName.isNotEmpty ? taxName : Localization.translate('unknown'),
                ),
                _buildDetailRow(
                  context,
                  Localization.translate('na2_code'),
                  na2Code.isNotEmpty ? na2Code : Localization.translate('unknown'),
                ),
                _buildDetailRow(
                  context,
                  Localization.translate('ynl'),
                  ynl.isNotEmpty ? ynl : Localization.translate('unknown'),
                ),
                _buildDetailRow(
                  context,
                  Localization.translate('period'),
                  period.isNotEmpty ? period : Localization.translate('unknown'),
                ),
                _buildDetailRow(
                  context,
                  Localization.translate('payment_date'),
                  paymentDate.isNotEmpty
                      ? paymentDate
                      : Localization.translate('unknown'),
                ),
                _buildDetailRow(
                  context,
                  Localization.translate('days_until_payment'),
                  daysUntilText,
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

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  // Helper method to build detail rows consistently
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
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
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
            final compositeKey =
                '${tax['na2_code']}_${tax['payment_date']}';
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
      bottomNavigationBar: BottomAppBar(
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
}

class SavedTaxCard extends StatelessWidget {
  final Map<String, dynamic> tax;
  final VoidCallback onStarToggled;
  final VoidCallback onInfoPressed;

  const SavedTaxCard({
    required this.tax,
    required this.onStarToggled,
    required this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String taxName = Localization.currentLanguage == 'ru'
        ? tax['tax_name_ru']?.toString() ?? ''
        : tax['tax_name_uz']?.toString() ?? '';
    final String period = Localization.currentLanguage == 'ru'
        ? tax['period_uz']?.toString() ?? ''
        : tax['period_uz']?.toString() ?? '';
    final String rawNa2Code = tax['na2_code']?.toString() ?? '';
    final String na2Code = rawNa2Code.contains('_')
        ? rawNa2Code.split('_').first
        : rawNa2Code;

    // Debug: Log na2Code to verify
    debugPrint('SavedTaxCard na2Code: $na2Code');

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
                    '${Localization.translate('tax_name')}: ${taxName.isNotEmpty ? taxName : Localization.translate('unknown')}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Localization.translate('ynl')}: ${tax['ynl']?.toString() ?? Localization.translate('unknown')}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Localization.translate('period')}: ${period.isNotEmpty ? period : Localization.translate('unknown')}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Localization.translate('payment_date')}: ${tax['payment_date']?.toString() ?? Localization.translate('unknown')}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Localization.translate('na2_code')}: ${na2Code.isNotEmpty ? na2Code : Localization.translate('unknown')}',
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