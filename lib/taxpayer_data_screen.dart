import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';
import 'faktura_auth_screen.dart';
import 'dart:io';

class TaxpayerDataScreen extends StatefulWidget {
  const TaxpayerDataScreen({Key? key}) : super(key: key);

  @override
  _TaxpayerDataScreenState createState() => _TaxpayerDataScreenState();
}

class _TaxpayerDataScreenState extends State<TaxpayerDataScreen> {
  bool _isLoading = false;
  List<dynamic> _taxpayerData = [];
  bool _isAdLoaded = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _fetchTaxpayerData();
    if (!kIsWeb) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    if (kIsWeb) {
      if (kDebugMode) {
        print('TaxpayerDataScreen: Banner ads not supported on web');
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

  Future<void> _fetchTaxpayerData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('faktura_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localization.translate("auth_error").replaceAll("{error}", "No token found"))),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FakturaAuthScreen()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _taxpayerData = [];
    });

    try {
      final url = Uri.parse('https://api.faktura.uz/api/TaxpayerData');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'ToolBox/1.0 (Flutter; ${kIsWeb ? 'Web' : Platform.operatingSystem})',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (kDebugMode) {
        print('TaxpayerDataScreen: Response status: ${response.statusCode}');
        print('TaxpayerDataScreen: Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] == null) {
          throw Exception('No data returned from API');
        }
        setState(() {
          _taxpayerData = data['data'];
        });
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Localization.translate("data_error").replaceAll("{error}", "Unauthorized"))),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FakturaAuthScreen()),
        );
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TaxpayerDataScreen: Error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate("data_error").replaceAll("{error}", e.toString())),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
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
          title: Text(Localization.translate("taxpayer_data_title")),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_taxpayerData.isEmpty && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const FakturaAuthScreen()),
                      );
                    },
                    child: Text(Localization.translate("reauthenticate")),
                  ),
                ),
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
                        Localization.translate("data_loading"),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                )
                    : _taxpayerData.isEmpty
                    ? Center(
                  child: Text(
                    Localization.translate("no_data"),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: _taxpayerData.length,
                  itemBuilder: (context, index) {
                    final item = _taxpayerData[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(item['name'] ?? Localization.translate("unknown")),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TIN: ${item['tin'] ?? Localization.translate("unknown")}'),
                            Text('Status: ${item['status'] ?? Localization.translate("unknown")}'),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(Localization.translate("taxpayer_data_title")),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Name: ${item['name'] ?? Localization.translate("unknown")}'),
                                  Text('TIN: ${item['tin'] ?? Localization.translate("unknown")}'),
                                  Text('Status: ${item['status'] ?? Localization.translate("unknown")}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(Localization.translate("close")),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
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