import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  final int _maxFailedLoadAttempts = 3;
  DateTime? _lastAdShown;
  final Duration _adCooldown = const Duration(minutes: 5);

  void loadInterstitialAd({
    required String androidAdUnitId,
    required String iosAdUnitId,
    required Function(String) onAdFailedToLoad,
  }) {
    if (kIsWeb) {
      if (kDebugMode) {
        print('AdManager: Ads not supported on web');
      }
      return; // Skip ad loading on web
    }

    if (_interstitialAd != null) return;

    if (kDebugMode) {
      print('AdManager: Loading interstitial ad...');
    }

    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? androidAdUnitId : iosAdUnitId,
      request: const AdRequest(
        httpTimeoutMillis: 10000,
      ),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('AdManager: Interstitial ad loaded successfully');
          }
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              if (kDebugMode) {
                print('AdManager: Interstitial ad shown');
              }
            },
            onAdDismissedFullScreenContent: (ad) {
              if (kDebugMode) {
                print('AdManager: Interstitial ad dismissed');
              }
              ad.dispose();
              _interstitialAd = null;
              _lastAdShown = DateTime.now();
              loadInterstitialAd(
                androidAdUnitId: androidAdUnitId,
                iosAdUnitId: iosAdUnitId,
                onAdFailedToLoad: onAdFailedToLoad,
              );
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) {
                print('AdManager: Interstitial ad failed to show: $error');
              }
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(
                androidAdUnitId: androidAdUnitId,
                iosAdUnitId: iosAdUnitId,
                onAdFailedToLoad: onAdFailedToLoad,
              );
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('AdManager: Interstitial ad failed to load: $error');
          }
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts < _maxFailedLoadAttempts) {
            loadInterstitialAd(
              androidAdUnitId: androidAdUnitId,
              iosAdUnitId: iosAdUnitId,
              onAdFailedToLoad: onAdFailedToLoad,
            );
          } else {
            onAdFailedToLoad(error.message);
          }
        },
      ),
    );
  }

  bool canShowAd() {
    if (kIsWeb) return false; // No ads on web
    return _interstitialAd != null &&
        (_lastAdShown == null ||
            DateTime.now().difference(_lastAdShown!).inSeconds > _adCooldown.inSeconds);
  }

  void showInterstitialAd() {
    if (canShowAd()) {
      if (kDebugMode) {
        print('AdManager: Showing interstitial ad');
      }
      _interstitialAd!.show();
    } else {
      if (kDebugMode) {
        print('AdManager: Cannot show ad (not loaded or in cooldown)');
      }
    }
  }

  void dispose() {
    if (kDebugMode) {
      print('AdManager: Disposing interstitial ad');
    }
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}