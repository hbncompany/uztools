import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'localization.dart';
import 'dart:io';

class NdsPayerScreen extends StatefulWidget {
  const NdsPayerScreen({Key? key}) : super(key: key);

  @override
  _NdsPayerScreenState createState() => _NdsPayerScreenState();
}

class _NdsPayerScreenState extends State<NdsPayerScreen> {
  final TextEditingController _innController = TextEditingController();
  bool _isLoading = false;
  bool? _isNdsPayer;
  bool _isAdLoaded = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    if (kIsWeb) {
      if (kDebugMode) {
        print('NdsPayerScreen: Banner ads not supported on web');
      }
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-7480088562684396/3085989451'
          : 'ca-app-pub-7480088562684396/3085989451',
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

  Future<void> _checkNdsPayer(String inn) async {
    if (!_validateInn(inn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localization.translate("invalid_inn"))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isNdsPayer = null;
    });

    try {
      final url = Uri.parse('https://api.faktura.uz/Api/Company/IsNdsPayer/$inn');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'ToolBox/1.0 (Flutter; ${kIsWeb ? 'Web' : Platform.operatingSystem})',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (kDebugMode) {
        print('NdsPayerScreen: Response status: ${response.statusCode}');
        print('NdsPayerScreen: Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Parse the response body
        final responseBody = response.body.trim();
        bool isNdsPayer;
        if (responseBody == 'true' || responseBody == 'false') {
          isNdsPayer = responseBody == 'true';
        } else {
          // Try JSON parsing as a fallback
          final data = jsonDecode(responseBody);
          if (data is bool) {
            isNdsPayer = data;
          } else if (data is Map<String, dynamic>) {
            isNdsPayer = data['isNdsPayer'] ?? false;
          } else {
            throw Exception('Unexpected response format: $responseBody');
          }
        }
        setState(() {
          _isNdsPayer = isNdsPayer;
        });
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NdsPayerScreen: Error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate("nds_error").replaceAll("{error}", e.toString())),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateInn(String inn) {
    return RegExp(r'^\d{9}$').hasMatch(inn);
  }

  Future<bool> _onWillPop() async {
    return true;
  }

  @override
  void dispose() {
    _innController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Localization.translate("nds_payer_title")),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _innController,
                decoration: InputDecoration(
                  hintText: Localization.translate("inn_hint"),
                  hintStyle: TextStyle(color: Colors.orangeAccent),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    color: Colors.green,
                    onPressed: () => _checkNdsPayer(_innController.text.trim()),
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) => _checkNdsPayer(value.trim()),
              ),
              const SizedBox(height: 16),
              Expanded(
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
                        Localization.translate("nds_loading"),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                )
                    : _isNdsPayer == null
                    ? Center(
                  child: Text(
                    Localization.translate("no_company_data"),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                )
                    : Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isNdsPayer!
                              ? Localization.translate("is_nds_payer")
                              : Localization.translate("not_nds_payer"),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('INN: ${_innController.text}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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