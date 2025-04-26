import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'localization.dart';
import 'dart:io';

class NdsNumberCheckScreen extends StatefulWidget {
  const NdsNumberCheckScreen({Key? key}) : super(key: key);

  @override
  _NdsNumberCheckScreenState createState() => _NdsNumberCheckScreenState();
}

class _NdsNumberCheckScreenState extends State<NdsNumberCheckScreen> {
  final TextEditingController _innController = TextEditingController();
  bool _isLoading = false;
  bool? _isNdsPayer;
  String nds_number = "";
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
        print('NdsNumberCheckScreen: Banner ads not supported on web');
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
      nds_number = "";
    });

    try {
      final url = Uri.parse('https://api.faktura.uz/Api/Company/GetNdsVatCode/$inn');
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
        print('NdsNumberCheckScreen: Response status: ${response.statusCode}');
        print('NdsNumberCheckScreen: Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        String vatCode = "";
        bool isNdsPayer = false;

        // Handle raw string response
        if (responseBody.isNotEmpty && responseBody != 'null') {
          try {
            // Try JSON parsing for structured response
            final data = jsonDecode(responseBody);
            if (data is Map<String, dynamic> && data['vatCode'] != null) {
              vatCode = data['vatCode'].toString();
              isNdsPayer = vatCode.isNotEmpty;
            } else if (data is String) {
              vatCode = data;
              isNdsPayer = vatCode.isNotEmpty;
            } else {
              throw Exception('Unexpected JSON response format: $responseBody');
            }
          } catch (e) {
            // Assume raw string is the VAT code
            vatCode = responseBody;
            isNdsPayer = vatCode.isNotEmpty;
          }
        }

        setState(() {
          nds_number = vatCode;
          _isNdsPayer = isNdsPayer;
        });
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NdsNumberCheckScreen: Error: $e');
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
          title: Text(Localization.translate("nds_number_title")),
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
                        if (_isNdsPayer! && nds_number.isNotEmpty)
                          Text(
                            Localization.translate("nds_vat_code").replaceAll("{code}", nds_number),
                            style: const TextStyle(fontSize: 16),
                          ),
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