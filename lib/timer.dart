import 'package:flutter/material.dart';
import 'dart:async';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _seconds = 0;
  int _minutes = 0;
  int _hours = 0;
  bool _isRunning = false;
  late Timer _timer;

  void _startTimer() {
    if (!_isRunning && (_seconds > 0 || _minutes > 0 || _hours > 0)) {
      _isRunning = true;
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else if (_minutes > 0) {
            _minutes--;
            _seconds = 59;
          } else if (_hours > 0) {
            _hours--;
            _minutes = 59;
            _seconds = 59;
          } else {
            _isRunning = false;
            timer.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Taymer yakunlandi!')),
            );
          }
        });
      });
    }
  }

  void _pauseTimer() {
    if (_isRunning) {
      _timer.cancel();
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _resetTimer() {
    if (_isRunning) {
      _timer.cancel();
    }
    setState(() {
      _seconds = 0;
      _minutes = 0;
      _hours = 0;
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    if (_isRunning) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Taymer'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer Display
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
                '${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            SizedBox(height: 40),

            // Time Input
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimePicker('Soat', _hours, (value) {
                  if (!_isRunning) {
                    setState(() => _hours = value);
                  }
                }),
                SizedBox(width: 20),
                _buildTimePicker('Daqiqa', _minutes, (value) {
                  if (!_isRunning) {
                    setState(() => _minutes = value);
                  }
                }),
                SizedBox(width: 20),
                _buildTimePicker('Soniya', _seconds, (value) {
                  if (!_isRunning) {
                    setState(() => _seconds = value);
                  }
                }),
              ],
            ),
            SizedBox(height: 40),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    _isRunning ? "To'xtatish" : 'Boshlash',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _resetTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Yangilash',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 80,
          child: TextField(
            enabled: !_isRunning,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            controller: TextEditingController(text: value.toString())
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: value.toString().length),
              ),
            onChanged: (text) {
              final newValue = int.tryParse(text) ?? value;
              if (newValue >= 0) {
                if (label == 'Soat' && newValue <= 23) onChanged(newValue);
                if (label == 'Daqiqa' && newValue <= 59) onChanged(newValue);
                if (label == 'Soniya' && newValue <= 59) onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }
}