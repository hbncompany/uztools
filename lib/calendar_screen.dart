import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'localization.dart';
import 'tax_payment_dates_screen.dart'; // For PaymentDateCard

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedPayments = [];
  Map<DateTime, List<Map<String, dynamic>>> _paymentEvents = {};
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _starredTaxCodes = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
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

  Future<void> _fetchPaymentDates() async {
    try {
      final response = await http.get(
        Uri.parse('https://hbnnarzullayev.pythonanywhere.com/all_tax_payment_dates_app'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final payments = data.cast<Map<String, dynamic>>();
        final Map<DateTime, List<Map<String, dynamic>>> events = {};

        for (var payment in payments) {
          final paymentDateStr = payment['payment_date']?.toString() ?? '';
          if (paymentDateStr.isEmpty) continue;

          try {
            final paymentDate = DateTime.parse(paymentDateStr);
            final dateOnly = DateTime(paymentDate.year, paymentDate.month, paymentDate.day);
            if (!events.containsKey(dateOnly)) {
              events[dateOnly] = [];
            }
            events[dateOnly]!.add(payment);
          } catch (e) {
            debugPrint('Error parsing payment date $paymentDateStr: $e');
            continue;
          }
        }

        setState(() {
          _paymentEvents = events;
          _isLoading = false;
          _errorMessage = null;
          if (_selectedDay != null) {
            _selectedPayments = _getEventsForDay(_selectedDay!);
          }
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

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _paymentEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _toggleStarredTaxCode(Map<String, dynamic> payment) async {
    final prefs = await SharedPreferences.getInstance();
    final na2Code = payment['na2_code']?.toString() ?? '';
    final paymentDate = payment['payment_date']?.toString() ?? '';
    final compositeKey = '${na2Code}_$paymentDate';

    if (_starredTaxCodes.contains(compositeKey)) {
      _starredTaxCodes.remove(compositeKey);
      await prefs.remove('tax_$compositeKey');
    } else {
      _starredTaxCodes.add(compositeKey);
      final taxData = {
        'na2_code': na2Code,
        'payment_date': paymentDate,
        'tax_name_uz': payment['tax_name_uz']?.toString() ?? '',
        'tax_name_ru': payment['tax_name_ru']?.toString() ?? '',
        'ynl': payment['ynl']?.toString() ?? '',
        'period': payment['period']?.toString() ?? '',
        'period_uz': payment['period_uz']?.toString() ?? '',
        'PERIOD_RU': payment['PERIOD_RU']?.toString() ?? '',
      };
      await prefs.setString('tax_$compositeKey', jsonEncode(taxData));
    }

    await prefs.setStringList('starred_tax_codes', _starredTaxCodes.toList());
    setState(() {
      _starredTaxCodes = _starredTaxCodes; // Update UI
    });
  }

  void _showTaxDetails(BuildContext context, Map<String, dynamic> payment) {
    final String taxName = Localization.currentLanguage == 'ru'
        ? payment['tax_name_ru']?.toString() ?? ''
        : payment['tax_name_uz']?.toString() ?? '';
    final String na2Code = payment['na2_code']?.toString() ?? '';
    final String ynl = payment['ynl']?.toString() ?? '';
    final String period = Localization.currentLanguage == 'ru'
        ? payment['PERIOD_RU']?.toString() ?? ''
        : payment['period_uz']?.toString() ?? '';
    final String paymentDate = payment['payment_date']?.toString() ?? '';

    int daysUntil;
    try {
      final paymentDateParsed = DateTime.parse(paymentDate);
      final today = DateTime.now();
      final paymentDateOnly = DateTime(paymentDateParsed.year, paymentDateParsed.month, paymentDateParsed.day);
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
              onPressed: () => Navigator.pop(context),
              child: Text(Localization.translate('close')),
            ),
          ],
        );
      },
    );
  }

  String getCalendarLocale() {
    switch (Localization.currentLanguage) {
      case 'uz':
        return 'uz_UZ';
      case 'ru':
        return 'ru_RU';
      case 'en':
      default:
        return 'en_US';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('calendar_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                onPressed: _fetchPaymentDates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
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
            : Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedPayments = _getEventsForDay(selectedDay);
                });
              },
              locale: getCalendarLocale(),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                weekendStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              eventLoader: _getEventsForDay,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    final daysUntil = day.difference(DateTime.now()).inDays;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: daysUntil < 7 ? Colors.red : Colors.blue,
                          width: 2,
                        ),
                      ),
                      width: 40,
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: Colors.orangeAccent
                            // color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            Expanded(
              child: _selectedPayments.isEmpty
                  ? Center(
                child: Text(
                  Localization.translate('no_payments_selected'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _selectedPayments.length,
                itemBuilder: (context, index) {
                  final payment = _selectedPayments[index];
                  final compositeKey =
                      '${payment['na2_code']}_${payment['payment_date']}';
                  return PaymentDateCard(
                    payment: payment,
                    isStarred: _starredTaxCodes.contains(compositeKey),
                    onStarToggled: () => _toggleStarredTaxCode(payment),
                    onInfoPressed: () => _showTaxDetails(context, payment),
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