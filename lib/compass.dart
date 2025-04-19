import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import 'localization.dart'; // Import your Localization class

class CompassScreen extends StatefulWidget {
  const CompassScreen({Key? key}) : super(key: key);

  @override
  _CompassScreenState createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? _direction;

  @override
  void initState() {
    super.initState();
    FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        _direction = event.heading;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('compass_title')),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _direction == null
                    ? Text(
                  Localization.translate('compass_not_working'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                )
                    : Stack(
                  alignment: Alignment.center,
                  children: [
                    // Compass background
                    Container(
                      width: 300,
                      height: 300,
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
                      child: CustomPaint(
                        painter: CompassPainter(),
                      ),
                    ),
                    // Rotating needle
                    Transform.rotate(
                      angle: ((_direction ?? 0) * (math.pi / 180) * -1),
                      child: Icon(
                        Icons.navigation,
                        size: 100,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _direction != null
                    ? Localization.translate('direction')
                    .replaceAll('{degrees}', _direction!.toStringAsFixed(0))
                    : Localization.translate('direction_unavailable'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    Localization.translate('north_label'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    Localization.translate('east_label'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    Localization.translate('west_label'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    Localization.translate('south_label'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw compass markings
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw cardinal directions
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final directions = [
      Localization.translate('north_short'),
      Localization.translate('east_short'),
      Localization.translate('south_short'),
      Localization.translate('west_short'),
    ];
    const angles = [0, 90, 180, 270];

    for (int i = 0; i < 4; i++) {
      final angle = angles[i] * math.pi / 180;
      final x = center.dx + (radius - 30) * math.cos(angle);
      final y = center.dy + (radius - 30) * math.sin(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );

      // Draw degree markings
      for (int deg = 0; deg < 360; deg += 10) {
        final angle = deg * math.pi / 180;
        final start = center +
            Offset(math.cos(angle) * (radius - 10), math.sin(angle) * (radius - 10));
        final end = center +
            Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}