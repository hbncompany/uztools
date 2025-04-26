import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';
import 'taxpayer_data_screen.dart';
import 'dart:io';

class FakturaAuthScreen extends StatefulWidget {
  const FakturaAuthScreen({Key? key}) : super(key: key);

  @override
  _FakturaAuthScreenState createState() => _FakturaAuthScreenState();
}

class _FakturaAuthScreenState extends State<FakturaAuthScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isAdLoaded = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            // Inject JavaScript to capture token from page content
            final token = await _controller.runJavaScriptReturningResult(
              'document.body.innerText.includes("access_token") ? JSON.parse(document.body.innerText).access_token : ""',
            );
            if (token.toString().isNotEmpty && token.toString() != '""') {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('faktura_token', token.toString().replaceAll('"', ''));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(Localization.translate("auth_success"))),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TaxpayerDataScreen()),
              );
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Localization.translate("auth_error").replaceAll("{error}", error.description),
                ),
              ),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check for redirect URLs containing token
            if (request.url.contains('access_token')) {
              final uri = Uri.parse(request.url);
              final token = uri.queryParameters['access_token'];
              if (token != null) {
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setString('faktura_token', token);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(Localization.translate("auth_success"))),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => TaxpayerDataScreen()),
                  );
                });
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://account.faktura.uz/token'));

    if (!kIsWeb) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    if (kIsWeb) {
      if (kDebugMode) {
        print('FakturaAuthScreen: Banner ads not supported on web');
      }
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
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

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Localization.translate("faktura_auth_title")),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Localization.translate("auth_loading"),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        bottomNavigationBar: _isAdLoaded && _bannerAd != null
            ? BottomAppBar(
          child: SizedBox(
            height: _bannerAd!.size.height.toDouble(),
            width: _bannerAd!.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        )
            : null,
      ),
    );
  }
}