import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static const String _adUnitId = 'ca-app-pub-7480088562684396/5696563669'; // Test ID
  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;
  int _adLoadAttempts = 0;
  static const int _maxAdLoadAttempts = 3;

  // Singleton instance
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // Load an interstitial ad
  Future<void> loadInterstitialAd() async {
    if (_isAdLoading || _adLoadAttempts >= _maxAdLoadAttempts) return;

    _isAdLoading = true;
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
          _adLoadAttempts = 0;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoading = false;
          _adLoadAttempts++;
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  // Show interstitial ad if loaded
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      print('Interstitial ad not ready');
    }
  }

  // Dispose of ad when no longer needed
  void dispose() {
    _interstitialAd?.dispose();
  }
}