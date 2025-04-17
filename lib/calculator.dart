import 'package:flutter/material.dart';
import 'localization.dart';

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = "0";
  String _currentNumber = "";
  String _operation = "";
  double _num1 = 0;
  double _num2 = 0;

  void buttonPressed(String buttonKey) {
    // Map translation keys to actual symbols for calculations
    final buttonMap = {
      Localization.translate('clear'): 'clear',
      Localization.translate('divide'): '÷',
      Localization.translate('multiply'): '×',
      Localization.translate('subtract'): '-',
      Localization.translate('add'): '+',
      Localization.translate('equals'): '=',
      Localization.translate('decimal'): '.',
    };

    // Get the operational symbol or action
    String buttonText = buttonMap[buttonKey] ?? buttonKey;

    if (buttonText == 'clear') {
      _output = "0";
      _currentNumber = "";
      _operation = "";
      _num1 = 0;
      _num2 = 0;
    } else if (buttonText == "+" ||
        buttonText == "-" ||
        buttonText == "×" ||
        buttonText == "÷") {
      _num1 = double.parse(_output);
      _operation = buttonText;
      _currentNumber = "";
    } else if (buttonText == "=") {
      _num2 = double.parse(_output);
      if (_operation == "+") {
        _currentNumber = (_num1 + _num2).toString();
      }
      if (_operation == "-") {
        _currentNumber = (_num1 - _num2).toString();
      }
      if (_operation == "×") {
        _currentNumber = (_num1 * _num2).toString();
      }
      if (_operation == "÷") {
        _currentNumber = (_num1 / _num2).toString();
      }
      _operation = "";
      _num1 = 0;
      _num2 = 0;
    } else {
      _currentNumber = _currentNumber + buttonText;
    }

    setState(() {
      _output = _currentNumber.isEmpty ? "0" : _currentNumber;
      if (_output.endsWith(".0")) {
        _output = _output.substring(0, _output.length - 2);
      }
    });
  }

  Widget buildButton(String buttonKey, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: ElevatedButton(
          child: Text(
            buttonKey,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Theme.of(context).cardColor,
            foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
            padding: EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: () => buttonPressed(buttonKey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('calculator_title')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(20),
              alignment: Alignment.centerRight,
              child: Text(
                _output,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        buildButton("7"),
                        buildButton("8"),
                        buildButton("9"),
                        buildButton(Localization.translate('divide'),
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.2)),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton("4"),
                        buildButton("5"),
                        buildButton("6"),
                        buildButton(Localization.translate('multiply'),
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.2)),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton("1"),
                        buildButton("2"),
                        buildButton("3"),
                        buildButton(Localization.translate('subtract'),
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.2)),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton("0"),
                        buildButton(Localization.translate('decimal')),
                        buildButton(Localization.translate('equals'),
                            color: Theme.of(context).primaryColor),
                        buildButton(Localization.translate('add'),
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.2)),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton(Localization.translate('clear'),
                            color: Colors.red[100]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
