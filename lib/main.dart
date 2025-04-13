import 'package:flutter/material.dart';
import 'package:uztools/calculator.dart';
import 'package:uztools/flashlight.dart';
import 'package:uztools/compass.dart';
import 'package:uztools/timer.dart';
import 'package:uztools/notes.dart';
import 'package:uztools/convert.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize(); // Initialize AdMob
  runApp(ToolsApp());
}

class ToolsApp extends StatefulWidget {
  @override
  _ToolsAppState createState() => _ToolsAppState();
}

class _ToolsAppState extends State<ToolsApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ToolsHomeScreen(
        onThemeChanged: (isDark) {
          setState(() {
            _isDarkMode = isDark;
          });
        },
      ),
      theme: _isDarkMode ? _darkTheme : _lightTheme,
    );
  }

  final ThemeData _lightTheme = ThemeData(
    primaryColor: Colors.blueAccent,
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blueAccent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
      ),
    ),
  );

  final ThemeData _darkTheme = ThemeData(
    primaryColor: Colors.blueAccent,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blueAccent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
    cardColor: Colors.grey[800],
  );
}

class ToolsHomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  ToolsHomeScreen({required this.onThemeChanged});

  @override
  _ToolsHomeScreenState createState() => _ToolsHomeScreenState();
}

class _ToolsHomeScreenState extends State<ToolsHomeScreen> {
  final List<Map<String, dynamic>> tools = [
    {'title': 'Kalkulator', 'icon': Icons.calculate, 'color': Colors.blue},
    {'title': 'Fonar', 'icon': Icons.lightbulb, 'color': Colors.yellow[700]},
    {'title': 'Kompass', 'icon': Icons.explore, 'color': Colors.green},
    {'title': 'Timer', 'icon': Icons.timer, 'color': Colors.red},
    {'title': 'Valyuta kursi', 'icon': Icons.swap_horiz, 'color': Colors.purple},
    {'title': 'Qoralamalar', 'icon': Icons.note, 'color': Colors.orange},
  ];

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7480088562684396/3085989451', // Test ID, replace with your own
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToolBox'),
        elevation: 0,
      ),
      drawer: AppDrawer(onThemeChanged: widget.onThemeChanged),
      body: SafeArea(
        child: Column(
          children: [
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

  AppDrawer({required this.onThemeChanged});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isDarkMode = false;

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
                  'ToolBox',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Doim xizmatingizda!',
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
            title: Text('Mavzu'),
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
            leading: Icon(Icons.settings, color: Theme.of(context).primaryColor),
            title: Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.info, color: Theme.of(context).primaryColor),
            title: Text('About'),
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
          if (title == "Kalkulator") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalculatorScreen()),
            );
          } else if (title == "Fonar") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FlashlightScreen()),
            );
          } else if (title == "Kompass") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CompassScreen()),
            );
          } else if (title == "Timer") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TimerScreen()),
            );
          } else if (title == "Qoralamalar") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotesScreen()),
            );
          } else if (title == "Valyuta kursi") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ConverterScreen()),
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
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
