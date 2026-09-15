import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({
    super.key,
    this.title,
  });

  /// null = استعمل العنوان المترجم الافتراضي (القيم الافتراضية
  /// بالبارامترات لازم تكون const، فما بتقبل ترجمة).
  final String? title;

  static Future<String?> scan(
    BuildContext context, {
    String? title,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => BarcodeScannerScreen(title: title),
      ),
    );
  }

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _manualController = TextEditingController();
  bool _handled = false;
  bool _showManual = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim() ?? '';
      if (value.isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? l.scanBarcode),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showManual = !_showManual),
            child: Text(l.typeManually, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(onDetect: _onDetect),
          ),
          if (_showManual)
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l.enterCode,
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        final trimmed = value.trim();
                        if (trimmed.isNotEmpty) {
                          Navigator.of(context).pop(trimmed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      final trimmed = _manualController.text.trim();
                      if (trimmed.isNotEmpty) {
                        Navigator.of(context).pop(trimmed);
                      }
                    },
                    child: Text(l.ok),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
