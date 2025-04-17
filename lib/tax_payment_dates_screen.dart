import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';

class TaxPaymentDatesScreen extends StatefulWidget {
  final int groupId;
  final String taxName;

  const TaxPaymentDatesScreen({
    required this.groupId,
    required this.taxName,
  });

  @override
  _TaxPaymentDatesScreenState createState() => _TaxPaymentDatesScreenState();
}

class _TaxPaymentDatesScreenState extends State<TaxPaymentDatesScreen> {
  List<Map<String, dynamic>> _paymentDates = [];
  List<Map<String, dynamic>> _filteredPaymentDates = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedYNL;
  String? _selectedPeriod;
  String? _selectedNa2Code;
  String? _searchQuery;
  List<String> _ynlOptions = [];
  List<Map<String, dynamic>> _periodOptions = [];
  List<String> _na2CodeOptions = [];
  Set<String> _starredTaxCodes = {};

  @override
  void initState() {
    super.initState();
    _loadStarredTaxCodes();
    _fetchPaymentDates();
  }

  Future<void> _loadStarredTaxCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final starred = prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
    setState(() {
      _starredTaxCodes = starred;
    });
  }

  Future<void> _toggleStarredTaxCode(Map<String, dynamic> payment) async {
    final prefs = await SharedPreferences.getInstance();
    final na2Code = payment['na2_code']?.toString() ?? '';
    setState(() {
      if (_starredTaxCodes.contains(na2Code)) {
        _starredTaxCodes.remove(na2Code);
        prefs.remove('tax_$na2Code');
      } else {
        _starredTaxCodes.add(na2Code);
        final taxData = {
          'na2_code': na2Code,
          'tax_name_uz': payment['tax_name_uz']?.toString() ?? '',
          'tax_name_ru': payment['tax_name_ru']?.toString() ?? '',
          'payment_date': payment['payment_date']?.toString() ?? '',
          'ynl': payment['YNL']?.toString() ?? '',
          'period_uz': payment['period_uz']?.toString() ?? '',
          'PERIOD_RU': payment['PERIOD_RU']?.toString() ?? '',
        };
        prefs.setString('tax_$na2Code', jsonEncode(taxData));
      }
      prefs.setStringList('starred_tax_codes', _starredTaxCodes.toList());
    });
  }

  Future<void> _fetchPaymentDates() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://hbnnarzullayev.pythonanywhere.com/tax_payment_dates_app?group_id=${widget.groupId}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _paymentDates = data.cast<Map<String, dynamic>>();
          _filteredPaymentDates = _paymentDates;
          _ynlOptions = _paymentDates
              .map((p) => p['YNL']?.toString() ?? '')
              .toSet()
              .toList()
            ..sort();
          final periodMap = <String, Map<String, dynamic>>{};
          for (var p in _paymentDates) {
            final period = p['PERIOD'] != null
                ? int.tryParse(p['PERIOD'].toString()) ?? 0
                : 0;
            final periodUz = p['period_uz']?.toString() ?? '';
            final periodRu = p['PERIOD_RU']?.toString() ?? '';
            final key =
                Localization.currentLanguage == 'ru' ? periodRu : periodUz;
            if (!periodMap.containsKey(key) ||
                period < (periodMap[key]!['PERIOD'] as int)) {
              periodMap[key] = {
                'PERIOD': period,
                'period_uz': periodUz,
                'PERIOD_RU': periodRu,
              };
            }
          }
          _periodOptions = periodMap.values.toList()
            ..sort(
                (a, b) => (a['PERIOD'] as int).compareTo(b['PERIOD'] as int));
          _na2CodeOptions = _paymentDates
              .map((p) => p['na2_code']?.toString() ?? '')
              .toSet()
              .toList()
            ..sort();
          if (_selectedPeriod != null &&
              !_periodOptions.any((p) =>
                  (Localization.currentLanguage == 'ru'
                      ? p['PERIOD_RU']
                      : p['period_uz']) ==
                  _selectedPeriod)) {
            _selectedPeriod = null;
          }
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

  void _applyFilters() {
    setState(() {
      _filteredPaymentDates = _paymentDates.where((payment) {
        final bool matchesYNL = _selectedYNL == null ||
            (payment['YNL']?.toString() ?? '') == _selectedYNL;
        final bool matchesPeriod = _selectedPeriod == null ||
            (Localization.currentLanguage == 'ru'
                    ? (payment['PERIOD_RU']?.toString() ?? '')
                    : (payment['period_uz']?.toString() ?? '')) ==
                _selectedPeriod;
        final bool matchesNa2Code = _selectedNa2Code == null ||
            (payment['na2_code']?.toString() ?? '') == _selectedNa2Code;
        final bool matchesSearch = _searchQuery == null ||
            (Localization.currentLanguage == 'ru'
                    ? (payment['tax_name_ru']?.toString() ?? '')
                    : (payment['tax_name_uz']?.toString() ?? ''))
                .toLowerCase()
                .contains(_searchQuery!.toLowerCase());
        return matchesYNL && matchesPeriod && matchesNa2Code && matchesSearch;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedYNL = null;
      _selectedPeriod = null;
      _selectedNa2Code = null;
      _searchQuery = null;
      _filteredPaymentDates = _paymentDates;
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery ?? '';
        return AlertDialog(
          title: Text(Localization.translate('search_tax_name')),
          content: TextField(
            decoration: InputDecoration(
              hintText: Localization.translate('search_placeholder'),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              tempQuery = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(Localization.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = tempQuery.isEmpty ? null : tempQuery;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Text(Localization.translate('search')),
            ),
          ],
        );
      },
    );
  }

  void _showTaxDetails(BuildContext context, Map<String, dynamic> payment) {
    final String taxName = Localization.currentLanguage == 'ru'
        ? payment['tax_name_ru']?.toString() ?? ''
        : payment['tax_name_uz']?.toString() ?? '';
    final String na2Code = payment['na2_code']?.toString() ?? '';
    final String ynl = payment['YNL']?.toString() ?? '';
    final String period = Localization.currentLanguage == 'ru'
        ? payment['PERIOD_RU']?.toString() ?? ''
        : payment['period_uz']?.toString() ?? '';
    final String paymentDate = payment['payment_date']?.toString() ?? '';

    int daysUntil;
    try {
      final paymentDateParsed = DateTime.parse(paymentDate);
      final today = DateTime.now();
      final paymentDateOnly = DateTime(paymentDateParsed.year,
          paymentDateParsed.month, paymentDateParsed.day);
      final todayOnly = DateTime(today.year, today.month, today.day);
      daysUntil = paymentDateOnly.difference(todayOnly).inDays;
    } catch (e) {
      daysUntil = 0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Localization.translate('tax_details')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${Localization.translate('tax_name')}: $taxName',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),
                SizedBox(height: 8),
                Text(
                  '${Localization.translate('na2_code')}: $na2Code',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '${Localization.translate('ynl')}: $ynl',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '${Localization.translate('period')}: $period',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '${Localization.translate('payment_date')}: $paymentDate',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '${Localization.translate('days_until_payment')}: $daysUntil',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(Localization.translate('close')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('tax_payment_dates_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: Localization.translate('search_tax_name'),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.taxName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.45,
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: Localization.translate('filter_by_ynl'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      value: _selectedYNL,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            Localization.translate('all_ynl'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ..._ynlOptions.map((ynl) => DropdownMenuItem(
                              value: ynl,
                              child: Text(
                                ynl,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedYNL = value;
                          _applyFilters();
                        });
                      },
                      selectedItemBuilder: (context) => [
                        Text(
                          _selectedYNL ?? Localization.translate('all_ynl'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        ..._ynlOptions.map((ynl) => Text(
                              ynl,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.45,
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: Localization.translate('filter_by_period'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      value: _selectedPeriod,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            Localization.translate('all_periods'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ..._periodOptions.map((p) => DropdownMenuItem(
                              value: Localization.currentLanguage == 'ru'
                                  ? p['PERIOD_RU'] as String
                                  : p['period_uz'] as String,
                              child: Text(
                                Localization.currentLanguage == 'ru'
                                    ? p['PERIOD_RU'] as String
                                    : p['period_uz'] as String,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPeriod = value;
                          _applyFilters();
                        });
                      },
                      selectedItemBuilder: (context) => [
                        Text(
                          _selectedPeriod ??
                              Localization.translate('all_periods'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        ..._periodOptions.map((p) => Text(
                              Localization.currentLanguage == 'ru'
                                  ? p['PERIOD_RU'] as String
                                  : p['period_uz'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.95,
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: Localization.translate('filter_by_na2_code'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                ),
                value: _selectedNa2Code,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      Localization.translate('all_na2_codes'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ..._na2CodeOptions.map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(
                          code,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedNa2Code = value;
                    _applyFilters();
                  });
                },
                selectedItemBuilder: (context) => [
                  Text(
                    _selectedNa2Code ?? Localization.translate('all_na2_codes'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  ..._na2CodeOptions.map((code) => Text(
                        code,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      )),
                ],
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearFilters,
                child: Text(
                  Localization.translate('clear_filters'),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
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
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
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
                                onPressed: _fetchPaymentDates,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
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
                      : _filteredPaymentDates.isEmpty
                          ? Center(
                              child: Text(
                                Localization.translate('no_data'),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredPaymentDates.length,
                              itemBuilder: (context, index) {
                                final payment = _filteredPaymentDates[index];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: PaymentDateCard(
                                    payment: payment,
                                    isStarred: _starredTaxCodes.contains(
                                        payment['na2_code']?.toString() ?? ''),
                                    onStarToggled: () =>
                                        _toggleStarredTaxCode(payment),
                                    onInfoPressed: () =>
                                        _showTaxDetails(context, payment),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentDateCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final bool isStarred;
  final VoidCallback onStarToggled;
  final VoidCallback onInfoPressed;

  const PaymentDateCard({
    required this.payment,
    required this.isStarred,
    required this.onStarToggled,
    required this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String taxName = Localization.currentLanguage == 'ru'
        ? payment['tax_name_ru']?.toString() ?? ''
        : payment['tax_name_uz']?.toString() ?? '';
    final String period = Localization.currentLanguage == 'ru'
        ? payment['PERIOD_RU']?.toString() ?? ''
        : payment['period_uz']?.toString() ?? '';

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
                    '${Localization.translate('ynl')}: ${payment['YNL']?.toString() ?? ''}',
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
                    '${Localization.translate('payment_date')}: ${payment['payment_date']?.toString() ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Localization.translate('na2_code')}: ${payment['na2_code']?.toString() ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.info,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: onInfoPressed,
                  tooltip: Localization.translate('view_details'),
                ),
                IconButton(
                  icon: Icon(
                    isStarred ? Icons.star : Icons.star_border,
                    color: isStarred
                        ? Colors.amber
                        : Theme.of(context).iconTheme.color,
                  ),
                  onPressed: onStarToggled,
                  tooltip: isStarred
                      ? Localization.translate('remove_from_saved')
                      : Localization.translate('save_tax'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
