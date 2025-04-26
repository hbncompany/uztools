import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localization.dart';

class QrCodeScreen extends StatefulWidget {
  @override
  _QrCodeScreenState createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Generate Tab
  final TextEditingController _textController = TextEditingController();
  String _qrData = '';
  File? _centerImage;
  String? _generateError;
  // Scan Tab
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _qrController;
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
    _qrController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Generate Tab Methods
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _centerImage = File(pickedFile.path);
          _generateError = null;
        });
      }
    } catch (e) {
      setState(() {
        _generateError = Localization.translate('qr_error')
            .replaceAll('{error}', e.toString());
      });
    }
  }

  Future<void> _shareQrCode() async {
    if (_qrData.isEmpty) return;
    try {
      final qrImage = await _generateQrImage();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code.png');
      await file.writeAsBytes(qrImage);
      await Share.shareXFiles([XFile(file.path)],
          text: Localization.translate('qr_code_title'));
      setState(() {
        _generateError = null;
      });
    } catch (e) {
      setState() {
        _generateError = Localization.translate('qr_error')
            .replaceAll('{error}', e.toString());
      }

      ;
    }
  }

  Future<void> _saveQrCode() async {
    if (_qrData.isEmpty) return;
    try {
      final qrImage = await _generateQrImage();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code.png');
      await file.writeAsBytes(qrImage);
      setState(() {
        _generateError = null;
      });
    } catch (e) {
      setState(() {
        _generateError = Localization.translate('qr_error')
            .replaceAll('{error}', e.toString());
      });
    }
  }

  Future<Uint8List> _generateQrImage() async {
    final qrValidationResult = QrValidator.validate(
      data: _qrData,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (!qrValidationResult.isValid) {
      throw Exception('Invalid QR code data');
    }
    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      emptyColor: Theme.of(context).cardColor,
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
    final image = await painter.toImage(300);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Scan Tab Methods
  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _qrController = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        setState(() {
          _scannedResult = scanData.code;
          _scanError = null;
        });
        controller.pauseCamera();
      }
    }, onError: (e) {
      setState(() {
        _scanError = Localization.translate('qr_error')
            .replaceAll('{error}', e.toString());
      });
    });
  }

  Future<void> _scanFromImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) throw Exception('Invalid image');
        final result = await _decodeQrFromImage(bytes);
        setState(() {
          _scannedResult = result ?? Localization.translate('no_qr_found');
          _scanError =
          result == null ? Localization.translate('no_qr_found') : null;
        });
      }
    } catch (e) {
      setState(() {
        _scanError = Localization.translate('qr_error')
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
        final result = await _decodeQrFromImage(bytes);
        setState(() {
          _scannedResult = result ?? Localization.translate('no_qr_found');
          _scanError =
          result == null ? Localization.translate('no_qr_found') : null;
        });
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      setState(() {
        _scanError = Localization.translate('qr_error')
            .replaceAll('{error}', e.toString());
      });
    }
  }

  Future<String?> _decodeQrFromImage(Uint8List bytes) async {
    // Note: qr_code_scanner_plus doesn't support image decoding, so this is a placeholder
    // Use the `scan` package for actual QR decoding from images
    return null; // Placeholder: Replace with actual QR decoding
  }

  Future<void> _copyResult() async {
    if (_scannedResult != null &&
        _scannedResult!.isNotEmpty &&
        _scannedResult != Localization.translate('no_qr_found')) {
      await Clipboard.setData(ClipboardData(text: _scannedResult!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localization.translate('copy_result'))),
      );
    }
  }

  Future<void> _shareResult() async {
    if (_scannedResult != null &&
        _scannedResult!.isNotEmpty &&
        _scannedResult != Localization.translate('no_qr_found')) {
      await Share.share(_scannedResult!,
          subject: Localization.translate('qr_code_title'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('qr_code_title')),
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
                      _qrData = _textController.text.trim();
                      _generateError = null;
                    });
                  },
                  child: Text(Localization.translate('generate_qr')),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text(Localization.translate('pick_image')),
                ),
                if (_generateError != null)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _generateError!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (_qrData.isNotEmpty)
                  Center(
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Theme.of(context).cardColor,
                      foregroundColor:
                      Theme.of(context).textTheme.bodyMedium?.color,
                      embeddedImage: _centerImage != null && !kIsWeb
                          ? FileImage(_centerImage!)
                          : null,
                      embeddedImageStyle: QrEmbeddedImageStyle(
                        size: Size(40, 40),
                      ),
                    ),
                  ),
                if (_qrData.isNotEmpty) SizedBox(height: 16),
                if (_qrData.isNotEmpty)
                  ElevatedButton(
                    onPressed: _shareQrCode,
                    child: Text(Localization.translate('share_qr')),
                  ),
                if (_qrData.isNotEmpty) SizedBox(height: 8),
                if (_qrData.isNotEmpty)
                  ElevatedButton(
                    onPressed: _saveQrCode,
                    child: Text(Localization.translate('save_qr')),
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
                    child: QRView(
                      key: _qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: Theme.of(context).primaryColor,
                        borderRadius: 10,
                        borderLength: 30,
                        borderWidth: 10,
                        cutOutSize: 250,
                      ),
                    ),
                  )
                else
                  Text(
                    kIsWeb
                        ? Localization.translate('qr_error').replaceAll(
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
                    _scannedResult != Localization.translate('no_qr_found'))
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
