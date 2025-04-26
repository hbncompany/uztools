import 'package:flutter/material.dart';
import 'localization.dart';
import 'tax_types_screen.dart';
import 'interest_calculator_screen.dart';
import 'package:uztools/saved_taxes_screen.dart';
import 'package:uztools/mxik_search_screen.dart';
import 'package:uztools/taxpayer_data_screen.dart';
import 'package:uztools/nds_payer_screen.dart';
import 'package:uztools/nds_number_check.dart';
import 'package:uztools/my_soliq_creen.dart';

class TaxInstrumentsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> taxTools = [
    {
      'title': 'tax_payments',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
    },
    {
      'title': 'tax_penalties',
      'icon': Icons.warning,
      'color': Colors.red,
    },
    {
      'title': 'mxik_search_title',
      'icon': Icons.search,
      'color': Colors.red,
    },
    {
      'title': 'nds_payer_title',
      'icon': Icons.check_circle_outline,
      'color': Colors.green,
    },
    {
      'title': 'nds_number_title',
      'icon': Icons.find_in_page_outlined,
      'color': Colors.green,
    },
    {
      'title': 'cabinet',
      'icon': Icons.person_pin_outlined,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('tax_instruments_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: taxTools.length,
          itemBuilder: (context, index) {
            return ToolCard(
              title: taxTools[index]['title'],
              icon: taxTools[index]['icon'],
              color: taxTools[index]['color'],
            );
          },
        ),
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
          if (title == "tax_payments") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaxTypesScreen()),
            );
          } else if (title == "tax_penalties") {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => InterestCalculatorScreen()),
            );
          } else if (title == "saved_taxes_title") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SavedTaxesScreen()),
            );
          }
          else if (title == "mxik_search_title") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MxikSearchScreen()),
            );
          }
          else if (title == "nds_payer_title") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NdsPayerScreen()),
            );
          }
          else if (title == "nds_number_title") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NdsNumberCheckScreen()),
            );
          }
          else if (title == "cabinet") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SoliqWebViewScreen()),
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
              Localization.translate(title),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
