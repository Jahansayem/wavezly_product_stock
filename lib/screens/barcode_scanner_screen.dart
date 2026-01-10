import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/services/barcode_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  Product? _foundProduct;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final product = await _barcodeService.findProductByBarcode(code);

      if (product != null) {
        setState(() {
          _foundProduct = product;
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, product);
          Fluttertoast.showToast(
            msg: 'Added ${product.name} to cart',
            backgroundColor: ColorPalette.tealAccent,
            textColor: ColorPalette.white,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Product not found for barcode: $code',
          backgroundColor: ColorPalette.mandy,
          textColor: ColorPalette.white,
        );
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error scanning barcode: $e',
        backgroundColor: ColorPalette.mandy,
        textColor: ColorPalette.white,
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          await cameraController.toggleTorch();
                        },
                        icon: const Icon(
                          Icons.flashlight_on,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await cameraController.switchCamera();
                        },
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _foundProduct != null
                                ? Colors.green
                                : Colors.white,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_foundProduct == null)
                              const Text(
                                'Position barcode within frame',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _foundProduct!.name ?? 'Unknown',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Adding to cart...',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
