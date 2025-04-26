import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uztools/calculator.dart';
import 'package:uztools/flashlight.dart';
import 'package:uztools/compass.dart';
import 'package:uztools/timer.dart';
import 'package:uztools/notes.dart';
import 'package:uztools/convert.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uztools/interest_calculator_screen.dart';
import 'localization.dart';
import 'package:uztools/tax_types_screen.dart';
import 'package:uztools/tax_instruments_screen.dart';
import 'package:uztools/notification_service.dart';
import 'package:uztools/notification_helper.dart';
import 'package:uztools/notifications_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  initializeDateFormatting();
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.checkAndSendTaxNotifications(); // Initial check
  MobileAds.instance.initialize();
  await Localization.loadTranslations(); // Load translations
  runApp(ToolsApp());
}

class ToolsApp extends StatefulWidget {
  @override
  _ToolsAppState createState() => _ToolsAppState();
}

class _ToolsAppState extends State<ToolsApp> {
  bool _isDarkMode = false;
  String _language = 'uz';
  String _clndrLocale = 'uz';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _language = prefs.getString('language') ?? 'uz';
      Localization.setLanguage(_language);
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setString('language', _language);
  }

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
    _savePreferences();
  }

  void _changeLanguage(String language) {
    setState(() {
      _language = language;
      Localization.setLanguage(language);
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ToolsHomeScreen(
        onThemeChanged: _toggleTheme,
        onLanguageChanged: _changeLanguage,
      ),
      theme: _isDarkMode ? _darkTheme : _lightTheme,
    );
  }

  final ThemeData _lightTheme = ThemeData(
    // Primary color scheme
    primarySwatch: Colors.teal,
    primaryColor: Colors.teal[700],
    scaffoldBackgroundColor: Colors.grey[50],

    // AppBar styling
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.teal[700],
      foregroundColor: Colors.white,
      elevation: 4.0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Drawer styling
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.white,
      scrimColor: Colors.black54,
      surfaceTintColor: Colors.teal[700],
      elevation: 8.0,
    ),

    // Icon styling
    iconTheme: IconThemeData(
      color: Colors.teal[800],
      size: 24,
    ),

    // Button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal[600],
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Card styling
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    ),

    // Text styling
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.teal[900],
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.grey[800],
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.teal[800],
      ),
    ),

    // Input decoration for TextFields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.teal[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.teal[800]),
    ),
  );

// Dark Theme
  final ThemeData _darkTheme = ThemeData(
    // Primary color scheme
    primarySwatch: Colors.teal,
    primaryColor: Colors.blueGrey,
    scaffoldBackgroundColor: Colors.grey[850],

    // AppBar styling
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.orangeAccent,
      // elevation: 4.0,
      titleTextStyle: TextStyle(
        color: Colors.orange[300],
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Drawer styling
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.cyan,
      scrimColor: Colors.black87,
      surfaceTintColor: Colors.black54,
      elevation: 8.0,
    ),

    // Icon styling
    iconTheme: IconThemeData(
      color: Colors.teal[300],
      size: 24,
    ),

    // Button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.grey[900],
        backgroundColor: Colors.teal[400],
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        textStyle: TextStyle(
          fontSize: 16,
          color: Colors.orangeAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Card styling
    cardTheme: CardTheme(
      color: Colors.grey[800],
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    ),

    // Text styling
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.orangeAccent,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.orangeAccent,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        color: Colors.orangeAccent,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.teal[300],
      ),
    ),

    // Input decoration for TextFields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[700]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[600]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[300]!, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.teal[300]),
    ),
  );
}

class ToolsHomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(String) onLanguageChanged;

  ToolsHomeScreen({
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  _ToolsHomeScreenState createState() => _ToolsHomeScreenState();
}

class _ToolsHomeScreenState extends State<ToolsHomeScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> allTools = [
    {
      'title': 'Taxes',
      'icon': Icons.money,
      'color': Colors.teal,
      'isMain': true
    },
    {
      'title': 'calculator',
      'icon': Icons.calculate,
      'color': Colors.blue,
      'isMain': true
    },
    {
      'title': 'flashlight',
      'icon': Icons.lightbulb,
      'color': Colors.yellow[700],
      'isMain': true
    },
    {
      'title': 'compass',
      'icon': Icons.explore,
      'color': Colors.green,
      'isMain': false
    },
    {
      'title': 'timer',
      'icon': Icons.timer,
      'color': Colors.red,
      'isMain': true
    },
    {
      'title': 'converter',
      'icon': Icons.swap_horiz,
      'color': Colors.purple,
      'isMain': false
    },
    {
      'title': 'notes',
      'icon': Icons.note,
      'color': Colors.orange,
      'isMain': true
    },
    {
      'title': 'interest_calculator',
      'icon': Icons.percent,
      'color': Colors.teal,
      'isMain': false
    },
  ];
  int _notificationCount = 0;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    // Refresh count when returning from NotificationsScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      _loadNotificationCount();
    });
    _loadBannerAd();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  Future<void> _loadNotificationCount() async {
    final count = await NotificationHelper.getNotificationCount();
    setState(() {
      _notificationCount = count;
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7480088562684396/3085989451',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final tools = _selectedTabIndex == 0
        ? allTools
        : allTools.where((tool) => tool['isMain'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('app_title')),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationsScreen()),
                  );
                  await notificationService.init();
                  await notificationService.checkAndSendTaxNotifications(); // Initial check
                  _loadNotificationCount(); // Refresh count after returning
                },
                tooltip: Localization.translate('view_notifications'),
              ),
              if (_notificationCount > 0)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: Localization.translate('all_tab')),
                Tab(text: Localization.translate('main_tab')),
              ],
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    return ToolCard(
                      title: tools[index]['title'],
                      icon: tools[index]['icon'],
                      color: tools[index]['color'],
                    );
                  },
                ),
              ),
            ),
            if (_isAdLoaded && _bannerAd != null)
              Container(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(String) onLanguageChanged;

  AppDrawer({
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'uz';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'uz';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Localization.translate('app_title'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  Localization.translate('slogan'),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(Localization.translate('theme')),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                widget.onThemeChanged(value);
              },
              activeColor: Colors.blueAccent,
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.language,
              color: Theme.of(context).primaryColor,
            ),
            title: Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: [
                DropdownMenuItem(value: 'uz', child: Text('Oʻzbek')),
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  widget.onLanguageChanged(value);
                }
              },
            ),
          ),
          ListTile(
            leading:
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
            title: Text(Localization.translate('settings')),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.info, color: Theme.of(context).primaryColor),
            title: Text(Localization.translate('about')),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class ToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;

  const ToolCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (title == "calculator") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalculatorScreen()),
            );
          } else if (title == "flashlight") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FlashlightScreen()),
            );
          } else if (title == "compass") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CompassScreen()),
            );
          } else if (title == "timer") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TimerScreen()),
            );
          } else if (title == "notes") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotesScreen()),
            );
          } else if (title == "converter") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ConverterScreen()),
            );
          } else if (title == "interest_calculator") {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => InterestCalculatorScreen()),
            );
          } else if (title == "Taxes") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaxInstrumentsScreen()),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            SizedBox(height: 12),
            Container(
              alignment: Alignment.center,
              child: Text(
                Localization.translate(title),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
