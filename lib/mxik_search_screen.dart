import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'localization.dart';
import 'dart:io';

class MxikSearchScreen extends StatefulWidget {
  const MxikSearchScreen({Key? key}) : super(key: key);

  @override
  _MxikSearchScreenState createState() => _MxikSearchScreenState();
}

class _MxikSearchScreenState extends State<MxikSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _mxikResults = [];
  bool _isAdLoaded = false;
  BannerAd? _bannerAd;
  bool _isApiUnreachable = false;

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
        print('MxikSearchScreen: Banner ads not supported on web');
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

  Future<void> _searchMxik(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate("search_hint")),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _mxikResults = [];
      _isApiUnreachable = false;
    });

    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final isCode = RegExp(r'^\d{17}$').hasMatch(query);
      final baseUrl = isCode
          ? 'https://api.tasnif.soliq.uz/api/v1/mxik/details?code=$encodedQuery'
          : 'https://api.tasnif.soliq.uz/api/v1/mxik/search?query=$encodedQuery&limit=10';

      final url = Uri.parse(baseUrl);

      if (kDebugMode) {
        print('MxikSearchScreen: Sending request to $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent':
          'ToolBox/1.0 (Flutter; ${kIsWeb ? 'Web' : Platform.operatingSystem})',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (kDebugMode) {
        print('MxikSearchScreen: Response status: ${response.statusCode}');
        print('MxikSearchScreen: Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] == null) {
          throw Exception('No data returned from API');
        }
        setState(() {
          _mxikResults = isCode ? [data['data']] : data['data'];
        });
      } else {
        throw Exception(
            'Server error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MxikSearchScreen: Error: $e');
      }
      String errorMessage;
      if (e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('CORS')) {
        errorMessage = Localization.translate("cors_error");
        setState(() {
          _isApiUnreachable = true;
        });
      } else if (e.toString().contains('timed out') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage = Localization.translate("api_unreachable");
        setState(() {
          _isApiUnreachable = true;
        });
      } else {
        errorMessage = Localization.translate("search_error")
            .replaceAll("{error}", e.toString());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openTasnifWebView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(Localization.translate("mxik_search_title")),
            backgroundColor: Theme.of(context).primaryColor,
          ),
          body: WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadRequest(Uri.parse('https://tasnif.soliq.uz')),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate("mxik_search_title")),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: Localization.translate("search_hint"),
                hintStyle: TextStyle(color: Colors.deepOrangeAccent),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchMxik(_searchController.text.trim()),
                ),
              ),
              onSubmitted: (value) => _searchMxik(value.trim()),
            ),
            const SizedBox(height: 16),
            if (_isApiUnreachable)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: _openTasnifWebView,
                  child: Text(Localization.translate("try_web_search")),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
                  : _mxikResults.isEmpty
                  ? Center(
                child: Text(
                  Localization.translate("no_results"),
                  style: TextStyle(
                    fontSize: 18,
                    color:
                    Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _mxikResults.length,
                itemBuilder: (context, index) {
                  final item = _mxikResults[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(item['name'] ??
                          Localization.translate("unknown")),
                      subtitle: Text(
                          'Code: ${item['code'] ?? Localization.translate("unknown")}'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(Localization.translate(
                                "mxik_search_title")),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Name: ${item['name'] ?? Localization.translate("unknown")}'),
                                Text(
                                    'Code: ${item['code'] ?? Localization.translate("unknown")}'),
                                Text(
                                    'Section: ${item['section'] ?? Localization.translate("unknown")}'),
                                Text(
                                    'Group: ${item['group'] ?? Localization.translate("unknown")}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context),
                                child: Text(
                                    Localization.translate("close")),
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
    );
  }
}
