import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';

class SavedTaxesScreen extends StatefulWidget {
  const SavedTaxesScreen({Key? key}) : super(key: key);

  @override
  _SavedTaxesScreenState createState() => _SavedTaxesScreenState();
}

class _SavedTaxesScreenState extends State<SavedTaxesScreen> {
  List<Map<String, dynamic>> _savedTaxes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedTaxes();
  }

  Future<void> _loadSavedTaxes() async {
    final prefs = await SharedPreferences.getInstance();
    final starredCodes =
        prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
    final List<Map<String, dynamic>> taxes = [];
    for (var code in starredCodes) {
      final taxData = prefs.getString('tax_$code');
      if (taxData != null) {
        taxes.add(jsonDecode(taxData) as Map<String, dynamic>);
      }
    }
    setState(() {
      _savedTaxes = taxes;
      _isLoading = false;
    });
  }

  Future<void> _toggleStarredTax(String na2Code) async {
    final prefs = await SharedPreferences.getInstance();
    final starredCodes =
        prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
    if (starredCodes.contains(na2Code)) {
      starredCodes.remove(na2Code);
      prefs.remove('tax_$na2Code');
      await prefs.setStringList('starred_tax_codes', starredCodes.toList());
      _loadSavedTaxes(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('saved_taxes_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(12),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
            : _savedTaxes.isEmpty
                ? Center(
                    child: Text(
                      Localization.translate('no_saved_taxes'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _savedTaxes.length,
                    itemBuilder: (context, index) {
                      final tax = _savedTaxes[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: SavedTaxCard(
                          tax: tax,
                          onStarToggled: () =>
                              _toggleStarredTax(tax['na2_code'] as String),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class SavedTaxCard extends StatelessWidget {
  final Map<String, dynamic> tax;
  final VoidCallback onStarToggled;

  const SavedTaxCard({
    required this.tax,
    required this.onStarToggled,
  });

  @override
  Widget build(BuildContext context) {
    final String taxName = Localization.currentLanguage == 'ru'
        ? tax['tax_name_ru']?.toString() ?? ''
        : tax['tax_name_uz']?.toString() ?? '';
    final String period = Localization.currentLanguage == 'ru'
        ? tax['PERIOD_RU']?.toString() ?? ''
        : tax['period_uz']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Localization.translate('tax_name')}: $taxName',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Localization.translate('ynl')}: ${tax['ynl']?.toString() ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Localization.translate('period')}: $period',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Localization.translate('payment_date')}: ${tax['payment_date']?.toString() ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Localization.translate('na2_code')}: ${tax['na2_code']?.toString() ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onPressed: onStarToggled,
              tooltip: Localization.translate('remove_from_saved'),
            ),
          ],
        ),
      ),
    );
  }
}
