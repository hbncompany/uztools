import 'package:flutter/material.dart';

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

  void buttonPressed(String buttonText) {
    if (buttonText == "TOZALASH") {
      _output = "0";
      _currentNumber = "";
      _operation = "";
      _num1 = 0;
      _num2 = 0;
    } else if (buttonText == "+" || buttonText == "-" || buttonText == "×" || buttonText == "÷") {
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
      _output = _currentNumber;
      if (_output.endsWith(".0")) {
        _output = _output.substring(0, _output.length - 2);
      }
    });
  }

  Widget buildButton(String buttonText, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: ElevatedButton(
          child: Text(
            buttonText,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],  // Changed from primary
            foregroundColor: Colors.black,              // Changed from onPrimary
            padding: EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: () => buttonPressed(buttonText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kalkulator'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
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
                  color: Colors.blueAccent,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        buildButton("÷", color: Colors.blue[100]),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton("4"),
                        buildButton("5"),
                        buildButton("6"),
                        buildButton("×", color: Colors.blue[100]),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton("1"),
                        buildButton("2"),
                        buildButton("3"),
                        buildButton("-", color: Colors.blue[100]),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton("0"),
                        buildButton("."),
                        buildButton("=", color: Colors.blueAccent),
                        buildButton("+", color: Colors.blue[100]),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton("TOZALASH", color: Colors.red[100]),
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
