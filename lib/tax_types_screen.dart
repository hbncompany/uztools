import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'localization.dart';
import 'tax_payment_dates_screen.dart'; // New import
import 'package:uztools/saved_taxes_screen.dart';
import 'package:uztools/calendar_screen.dart';

class TaxTypesScreen extends StatefulWidget {
  @override
  _TaxTypesScreenState createState() => _TaxTypesScreenState();
}

class _TaxTypesScreenState extends State<TaxTypesScreen> {
  List<Map<String, dynamic>> _taxTypes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTaxTypes();
  }

  Future<void> _fetchTaxTypes() async {
    try {
      final response = await http.get(
        Uri.parse('https://hbnnarzullayev.pythonanywhere.com/tax_types_app'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _taxTypes = data.cast<Map<String, dynamic>>();
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = Localization.translate('error_loading_data')
              .replaceAll('{error}', 'Status ${response.statusCode}');
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = Localization.translate('error_loading_data')
            .replaceAll('{error}', e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('tax_types_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.star),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedTaxesScreen()),
              );
            },
            tooltip: Localization.translate('saved_taxes_title'),
          ),
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarScreen()),
              );
            },
            tooltip: Localization.translate('saved_taxes_title'),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(16),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      Localization.translate('loading'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTaxTypes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Theme.of(context)
                                .elevatedButtonTheme
                                .style
                                ?.foregroundColor
                                ?.resolve({}),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            Localization.translate('try_again'),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : _taxTypes.isEmpty
                    ? Center(
                        child: Text(
                          Localization.translate('no_data'),
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _taxTypes.length,
                        itemBuilder: (context, index) {
                          final taxType = _taxTypes[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: TaxTypeCard(
                              id: taxType['ID'],
                              name: Localization.currentLanguage == 'ru'
                                  ? taxType['group_name_ru']
                                  : taxType['group_name_uz'],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaxPaymentDatesScreen(
                                      groupId: taxType['ID'],
                                      taxName:
                                          Localization.currentLanguage == 'ru'
                                              ? taxType['group_name_ru']
                                              : taxType['group_name_uz'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class TaxTypeCard extends StatelessWidget {
  final int id;
  final String name;
  final VoidCallback onTap;

  const TaxTypeCard({
    required this.id,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$id',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
