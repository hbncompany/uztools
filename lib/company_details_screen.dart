import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';
import 'faktura_auth_screen.dart';
import 'dart:io';

class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({Key? key}) : super(key: key);

  @override
  _CompanyDetailsScreenState createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  final TextEditingController _innController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _companyData;
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
        print('CompanyDetailsScreen: Banner ads not supported on web');
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

  Future<void> _fetchCompanyDetails(String inn) async {
    if (!_validateInn(inn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localization.translate("invalid_inn"))),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('faktura_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localization.translate("company_error").replaceAll("{error}", "No token found"))),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FakturaAuthScreen()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _companyData = null;
    });

    try {
      final url = Uri.parse('https://api.faktura.uz/Api/Company/GetCompanyBasicDetails?companyInn=$inn');
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
        print('CompanyDetailsScreen: Response status: ${response.statusCode}');
        print('CompanyDetailsScreen: Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] == null) {
          throw Exception('No data returned from API');
        }
        setState(() {
          _companyData = data['data'];
        });
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Localization.translate("company_error").replaceAll("{error}", "Unauthorized"))),
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
        print('CompanyDetailsScreen: Error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate("company_error").replaceAll("{error}", e.toString())),
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
          title: Text(Localization.translate("company_details_title")),
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
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _fetchCompanyDetails(_innController.text.trim()),
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) => _fetchCompanyDetails(value.trim()),
              ),
              const SizedBox(height: 16),
              if (_companyData == null && !_isLoading)
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
                        Localization.translate("company_loading"),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                )
                    : _companyData == null
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
                          _companyData!['name'] ?? Localization.translate("unknown"),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('INN: ${_companyData!['inn'] ?? Localization.translate("unknown")}'),
                        Text('Address: ${_companyData!['address'] ?? Localization.translate("unknown")}'),
                        Text('Status: ${_companyData!['status'] ?? Localization.translate("unknown")}'),
                        Text(
                          'Registration Date: ${_companyData!['registrationDate'] ?? Localization.translate("unknown")}',
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