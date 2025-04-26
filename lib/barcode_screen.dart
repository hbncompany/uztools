import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:path_provider/path_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localization.dart';

class BarcodeScreen extends StatefulWidget {
  @override
  _BarcodeScreenState createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Generate Tab
  final TextEditingController _textController = TextEditingController();
  String _barcodeData = '';
  String? _generateError;
  final GlobalKey _barcodeKey = GlobalKey();
  // Scan Tab
  ms.MobileScannerController? _scannerController;
  final TextEditingController _urlController = TextEditingController();
  String? _scannedResult;
  String? _scanError;
  bool _hasCameraPermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasCameraPermission = status.isGranted;
      if (!status.isGranted) {
        _scanError = Localization.translate('camera_permission_denied');
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    _scannerController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Generate Tab Methods
  Future<void> _shareBarcode() async {
    if (_barcodeData.isEmpty) return;
    try {
      final barcodeImage = await _generateBarcodeImage();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/barcode.png');
      await file.writeAsBytes(barcodeImage);
      await share_plus.Share.shareXFiles(
        [XFile(file.path)],
        text: Localization.translate('barcode_title'),
      );
      setState(() {
        _generateError = null;
      });
    } catch (e) {
      setState(() {
        _generateError = Localization.translate('barcode_error')
            .replaceAll('{error}', e.toString());
      });
    }
  }

  Future<void> _saveBarcode() async {
    if (_barcodeData.isEmpty) return;
    try {
      final barcodeImage = await _generateBarcodeImage();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/barcode.png');
      await file.writeAsBytes(barcodeImage);
      setState(() {
        _generateError = null;
      });
    } catch (e) {
      setState(() {
        _generateError = Localization.translate('barcode_error')
            .replaceAll('{error}', e.toString());
      });
    }
  }

  Future<Uint8List> _generateBarcodeImage() async {
    if (_barcodeData.isEmpty) throw Exception('No barcode data');
    final renderObject = _barcodeKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw Exception('Failed to find RenderRepaintBoundary');
    }
    final uiImage = await renderObject.toImage(pixelRatio: 3.0);
    final byteData = await uiImage.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Scan Tab Methods
  void _onDetect(ms.BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      setState(() {
        _scannedResult = barcode!.rawValue;
        _scanError = null;
      });
      _scannerController?.stop();
    }
  }

  Future<void> _scanFromImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) throw Exception('Invalid image');
        final result = await _decodeBarcodeFromImage(bytes);
        setState(() {
          _scannedResult = result ?? Localization.translate('no_barcode_found');
          _scanError = result == null
              ? Localization.translate('no_barcode_found')
              : null;
        });
      }
    } catch (e) {
      setState(() {
        _scanError = Localization.translate('barcode_error')
            .replaceAll('{error}', e.toString());
      });
    }
  }

  Future<void> _scanFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _scanError = Localization.translate('invalid_url');
      });
      return;
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final image = img.decodeImage(bytes);
        if (image == null) throw Exception('Invalid image');
        final result = await _decodeBarcodeFromImage(bytes);
        setState(() {
          _scannedResult = result ?? Localization.translate('no_barcode_found');
          _scanError = result == null
              ? Localization.translate('no_barcode_found')
              : null;
        });
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      setState(() {
        _scanError = Localization.translate('barcode_error')
            .replaceAll('{error}', e.toString());
      });
    }
  }

  Future<String?> _decodeBarcodeFromImage(Uint8List bytes) async {
    // Note: mobile_scanner doesn't support image decoding, so this is a placeholder
    // Use the `scan` package for actual barcode decoding from images
    return null; // Placeholder: Replace with actual barcode decoding
  }

  Future<void> _copyResult() async {
    if (_scannedResult != null &&
        _scannedResult!.isNotEmpty &&
        _scannedResult != Localization.translate('no_barcode_found')) {
      await Clipboard.setData(ClipboardData(text: _scannedResult!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localization.translate('copy_result'))),
      );
    }
  }

  Future<void> _shareResult() async {
    if (_scannedResult != null &&
        _scannedResult!.isNotEmpty &&
        _scannedResult != Localization.translate('no_barcode_found')) {
      await share_plus.Share.share(
        _scannedResult!,
        subject: Localization.translate('barcode_title'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('barcode_title')),
        backgroundColor: Theme.of(context).primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: Localization.translate('generate_tab')),
            Tab(text: Localization.translate('scan_tab')),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Generate Tab
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    labelText: Localization.translate('enter_text'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _barcodeData = _textController.text.trim();
                      _generateError = null;
                    });
                  },
                  child: Text(Localization.translate('generate_barcode')),
                ),
                if (_generateError != null)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _generateError!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (_barcodeData.isNotEmpty)
                  Center(
                    child: RepaintBoundary(
                      key: _barcodeKey,
                      child: bw.BarcodeWidget(
                        barcode: bw.Barcode.code128(),
                        data: _barcodeData,
                        width: 300,
                        height: 100,
                        color: Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.black,
                        backgroundColor: Theme.of(context).cardColor,
                        drawText: true,
                      ),
                    ),
                  ),
                if (_barcodeData.isNotEmpty) SizedBox(height: 16),
                if (_barcodeData.isNotEmpty)
                  ElevatedButton(
                    onPressed: _shareBarcode,
                    child: Text(Localization.translate('share_barcode')),
                  ),
                if (_barcodeData.isNotEmpty) SizedBox(height: 8),
                if (_barcodeData.isNotEmpty)
                  ElevatedButton(
                    onPressed: _saveBarcode,
                    child: Text(Localization.translate('save_barcode')),
                  ),
              ],
            ),
          ),
          // Scan Tab
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasCameraPermission && !kIsWeb)
                  Container(
                    height: 300,
                    child: ms.MobileScanner(
                      controller: _scannerController =
                          ms.MobileScannerController(),
                      onDetect: _onDetect,
                    ),
                  )
                else
                  Text(
                    kIsWeb
                        ? Localization.translate('barcode_error').replaceAll(
                        '{error}', 'Camera not supported on web')
                        : Localization.translate('camera_permission_denied'),
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: kIsWeb ? null : _scanFromImage,
                  child: Text(Localization.translate('scan_from_image')),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: Localization.translate('enter_url'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _scanFromUrl,
                  child: Text(Localization.translate('scan_from_url')),
                ),
                if (_scanError != null)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _scanError!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (_scannedResult != null)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      Localization.translate('scanned_result')
                          .replaceAll('{result}', _scannedResult!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                if (_scannedResult != null &&
                    _scannedResult !=
                        Localization.translate('no_barcode_found'))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _copyResult,
                        child: Text(Localization.translate('copy_result')),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _shareResult,
                        child: Text(Localization.translate('share_result')),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
