import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';

class FlashlightScreen extends StatefulWidget {
  @override
  _FlashlightScreenState createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen> {
  bool _isFlashOn = false;
  bool _hasFlashlight = true;

  @override
  void initState() {
    super.initState();
    _checkFlashlightAvailability();
  }

  Future<void> _checkFlashlightAvailability() async {
    try {
      bool hasTorch = await TorchLight.isTorchAvailable();
      setState(() {
        _hasFlashlight = hasTorch;
      });
    } catch (e) {
      setState(() {
        _hasFlashlight = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fonar topilmadi: $e')),
      );
    }
  }

  Future<void> _toggleFlashlight() async {
    try {
      if (_isFlashOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fonar bilan ishlashda xatolik: $e")),
      );
    }
  }

  @override
  void dispose() {
    if (_isFlashOn) {
      TorchLight.disableTorch();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fonar'),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _isFlashOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  size: 100,
                  color: _isFlashOn ? Colors.yellow[700] : Colors.grey[400],
                ),
              ),
              SizedBox(height: 40),
              if (!_hasFlashlight)
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Bu qurilmada fonar mavjud emas",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _hasFlashlight ? _toggleFlashlight : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFlashOn ? Colors.red[400] : Colors.yellow[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isFlashOn ? "O'chirish" : "Yoqish",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}