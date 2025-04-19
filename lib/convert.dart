import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'localization.dart'; // Import your Localization class

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({Key? key}) : super(key: key);

  @override
  _ConverterScreenState createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  List<dynamic> _currencies = [];
  String? _fromCurrency = 'USD';
  String? _toCurrency = 'UZS';
  double _amount = 0.0;
  double _result = 0.0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurrencies();
  }

  Future<void> _fetchCurrencies() async {
    try {
      final response = await http.get(Uri.parse('https://cbu.uz/uz/arkhiv-kursov-valyut/json/'));
      if (response.statusCode == 200) {
        setState(() {
          _currencies = json.decode(response.body);
          _currencies.insert(0, {
            'Ccy': 'UZS',
            'Rate': '1.0',
            'CcyNm_EN': Localization.translate('uzs_name'),
          }); // Add UZS as base currency
          _isLoading = false;
        });
      } else {
        throw Exception(Localization.translate('fetch_error').replaceAll('{code}', response.statusCode.toString()));
      }
    } catch (e) {
      setState(() {
        _errorMessage = Localization.translate('fetch_error').replaceAll('{error}', e.toString());
        _isLoading = false;
      });
    }
  }

  void _convert() {
    if (_amount <= 0) return;

    double fromRate = _fromCurrency == 'UZS'
        ? 1.0
        : double.parse(_currencies.firstWhere((c) => c['Ccy'] == _fromCurrency)['Rate']);
    double toRate = _toCurrency == 'UZS'
        ? 1.0
        : double.parse(_currencies.firstWhere((c) => c['Ccy'] == _toCurrency)['Rate']);

    setState(() {
      _result = (_amount * fromRate) / toRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('currency_converter_title')),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Input
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: Localization.translate('amount_label'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                onChanged: (value) {
                  setState(() {
                    _amount = double.tryParse(value) ?? 0.0;
                    _convert();
                  });
                },
              ),
              const SizedBox(height: 20),

              // From Currency Dropdown
              DropdownButtonFormField<String>(
                value: _fromCurrency,
                decoration: InputDecoration(
                  labelText: Localization.translate('from_currency_label'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                items: _currencies.map((currency) {
                  return DropdownMenuItem<String>(
                    value: currency['Ccy'],
                    child: Text('${currency['Ccy']} - ${currency['CcyNm_EN']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _fromCurrency = value;
                    _convert();
                  });
                },
              ),
              const SizedBox(height: 20),

              // To Currency Dropdown
              DropdownButtonFormField<String>(
                value: _toCurrency,
                decoration: InputDecoration(
                  labelText: Localization.translate('to_currency_label'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                items: _currencies.map((currency) {
                  return DropdownMenuItem<String>(
                    value: currency['Ccy'],
                    child: Text('${currency['Ccy']} - ${currency['CcyNm_EN']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _toCurrency = value;
                    _convert();
                  });
                },
              ),
              const SizedBox(height: 30),

              // Result Display
              Container(
                padding: const EdgeInsets.all(20),
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
                  _result > 0
                      ? Localization.translate('conversion_result')
                      .replaceAll('{amount}', _amount.toStringAsFixed(2))
                      .replaceAll('{from}', _fromCurrency ?? '')
                      .replaceAll('{result}', _result.toStringAsFixed(2))
                      .replaceAll('{to}', _toCurrency ?? '')
                      : Localization.translate('enter_amount_prompt'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Last Updated
              Text(
                Localization.translate('last_updated'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}