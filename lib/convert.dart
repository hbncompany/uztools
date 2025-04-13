import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConverterScreen extends StatefulWidget {
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
            'CcyNm_EN': 'Uzbekistan Som',
          }); // Add UZS as base currency
          _isLoading = false;
        });
      } else {
        throw Exception("Ma'lumot yuklashda xatolik: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Ma'lumot yuklashda xatolik: $e";
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
        title: Text('Valyuta kursi'),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(16),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Miqdor',
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
              SizedBox(height: 20),

              // From Currency Dropdown
              DropdownButtonFormField<String>(
                value: _fromCurrency,
                decoration: InputDecoration(
                  labelText: '...dan',
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
              SizedBox(height: 20),

              // To Currency Dropdown
              DropdownButtonFormField<String>(
                value: _toCurrency,
                decoration: InputDecoration(
                  labelText: '...ga',
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
              SizedBox(height: 30),

              // Result Display
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
                  _result > 0
                      ? '${_amount.toStringAsFixed(2)} $_fromCurrency = ${_result.toStringAsFixed(2)} $_toCurrency'
                      : "Miqdorni kiriting",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),

              // Last Updated
              Text(
                "Bugungi kun holatiga Markaziy bank ma'lumoti",
                style: TextStyle(
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