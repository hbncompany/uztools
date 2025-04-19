import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'localization.dart'; // Import your Localization class

class FlashlightScreen extends StatefulWidget {
  const FlashlightScreen({Key? key}) : super(key: key);

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
        SnackBar(
          content: Text(
            Localization.translate("flashlight_not_found").replaceAll("{error}", e.toString()),
          ),
        ),
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
        SnackBar(
          content: Text(
            Localization.translate("flashlight_error").replaceAll("{error}", e.toString()),
          ),
        ),
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
        title: Text(Localization.translate("flashlight_title")),
        backgroundColor: Colors.blueGrey[800],
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
              const SizedBox(height: 40),
              if (!_hasFlashlight)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    Localization.translate("no_flashlight_available"),
                    style: const TextStyle(
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
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isFlashOn
                        ? Localization.translate("turn_off")
                        : Localization.translate("turn_on"),
                    style: const TextStyle(
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