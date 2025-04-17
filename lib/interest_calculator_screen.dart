import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'localization.dart';

class InterestCalculatorScreen extends StatefulWidget {
  @override
  _InterestCalculatorScreenState createState() =>
      _InterestCalculatorScreenState();
}

class _InterestCalculatorScreenState extends State<InterestCalculatorScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  double _amount = 0.0;
  double _result = 0.0;
  String? _errorMessage;

  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2007, 1, 1),
      lastDate: DateTime(3000, 1, 1),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          _fromDateController.text = DateFormat('dd.MM.yyyy').format(picked);
        } else {
          _toDate = picked;
          _toDateController.text = DateFormat('dd.MM.yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _calculateInterest() async {
    // Validate inputs
    if (_fromDate == null || _toDate == null || _amount <= 0) {
      setState(() {
        _errorMessage = Localization.translate('error_invalid_input');
      });
      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      setState(() {
        _errorMessage = Localization.translate('error_invalid_date_range');
      });
      return;
    }

    // Prepare JSON payload
    final payload = {
      'from_date': DateFormat('yyyy-MM-dd').format(_fromDate!),
      'to_date': DateFormat('yyyy-MM-dd').format(_toDate!),
      'amount': _amount,
    };

    try {
      print('Sending payload: $payload');
      final response = await http.post(
        Uri.parse('https://hbnnarzullayev.pythonanywhere.com/tax_fines_app'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');
        print('Result value: ${data["result"]}');
        if (data['result'] != null) {
          try {
            // Handle result as String or number
            _result = (data['result'] is String)
                ? double.parse(data['result'])
                : (data['result'] is int)
                ? (data['result'] as int).toDouble()
                : data['result'] as double;
            setState(() {
              _errorMessage = null;
              print('Set _result: $_result');
            });
          } catch (e) {
            setState(() {
              _errorMessage = Localization.translate('error_invalid_response');
              print('Error parsing result: $e');
            });
          }
        } else {
          setState(() {
            _errorMessage = Localization.translate('error_invalid_response');
            print('Error: No result in response');
          });
        }
      } else {
        setState(() {
          _errorMessage = Localization.translate('error_api')
              .replaceAll('{error}', 'Status ${response.statusCode}');
          print('Error: Status ${response.statusCode}');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = Localization.translate('error_api')
            .replaceAll('{error}', e.toString());
        print('Exception: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building UI, _result: $_result, _errorMessage: $_errorMessage');
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('interest_calculator_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // From Date
              TextField(
                controller: _fromDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: Localization.translate('from_date'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context, true),
              ),
              SizedBox(height: 20),

              // To Date
              TextField(
                controller: _toDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: Localization.translate('to_date'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context, false),
              ),
              SizedBox(height: 20),

              // Amount Input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: Localization.translate('amount'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                onChanged: (value) {
                  setState(() {
                    _amount = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              SizedBox(height: 30),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculateInterest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context)
                      .elevatedButtonTheme
                      .style
                      ?.foregroundColor
                      ?.resolve({}),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  Localization.translate('calculate'),
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),

              // Result or Error
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              if (_result != 0)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    '${Localization.translate('fine_sum')}: ${_result.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}