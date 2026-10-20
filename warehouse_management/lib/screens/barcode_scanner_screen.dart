import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/models/fast_sale_scan_result.dart';
import 'package:wavezly/services/barcode_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum BarcodeScannerMode {
  lookupProduct, // Find existing product in DB (for sales/cart)
  captureBarcode, // Return raw barcode value (for new product)
  fastSaleSession, // Multi-scan session for Fast Sale (stay on camera)
}

class BarcodeScannerScreen extends StatefulWidget {
  final BarcodeScannerMode mode;

  const BarcodeScannerScreen({
    super.key,
    this.mode = BarcodeScannerMode.lookupProduct,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final BarcodeService _barcodeService = BarcodeService();
  MobileScannerController? cameraController;

  bool _isProcessing = false;
  bool _isInitializing = true;
  bool _hasCameraPermission = false;
  bool _isStarting = false;
  bool _isCameraStarted = false;
  String? _cameraError;
  Product? _foundProduct;

  // Fast Sale session state
  final Map<String, FastSaleScanItem> _scannedItems = {};
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const Duration _debounceWindow = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCameraSafely();
    cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop camera when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopCameraSafely();
    }
    // Restart camera when app returns to foreground (if permission granted)
    else if (state == AppLifecycleState.resumed) {
      if (_hasCameraPermission && !_isCameraStarted) {
        _startCameraSafely();
      }
    }
  }

  Future<void> _startCameraSafely() async {
    // Guard: prevent duplicate start calls
    if (_isStarting || _isCameraStarted || !mounted || cameraController == null) {
      return;
    }

    _isStarting = true;

    try {
      await cameraController!.start();
      if (mounted) {
        setState(() {
          _isCameraStarted = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      // Handle "already started" gracefully (non-fatal)
      if (e.toString().toLowerCase().contains('already started')) {
        if (mounted) {
          setState(() {
            _isCameraStarted = true;
            _cameraError = null;
          });
        }
      } else {
        // Other errors are fatal
        if (mounted) {
          setState(() {
            _cameraError = 'Camera start error: $e';
          });
        }
      }
    } finally {
      _isStarting = false;
    }
  }

  void _stopCameraSafely() {
    if (!_isCameraStarted || cameraController == null) {
      return;
    }

    try {
      cameraController!.stop();
      _isCameraStarted = false;
    } catch (e) {
      // Ignore stop errors
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _cameraError = null;
    });

    try {
      // Check camera permission
      final status = await Permission.camera.status;

      if (status.isGranted) {
        await _startCamera();
      } else if (status.isDenied) {
        // Request permission
        final result = await Permission.camera.request();
        if (result.isGranted) {
          await _startCamera();
        } else {
          setState(() {
            _hasCameraPermission = false;
            _isInitializing = false;
            _cameraError = 'Camera permission denied';
          });
        }
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _hasCameraPermission = false;
          _isInitializing = false;
          _cameraError = 'Camera permission permanently denied';
        });
      }
    } catch (e) {
      setState(() {
        _hasCameraPermission = false;
        _isInitializing = false;
        _cameraError = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _startCamera() async {
    try {
      // Create controller with autoStart: false to prevent immediate start
      cameraController = MobileScannerController(
        autoStart: false,
      );

      setState(() {
        _hasCameraPermission = true;
        _isInitializing = false;
        _cameraError = null;
      });

      // Now explicitly start the camera using safe method
      await _startCameraSafely();
    } catch (e) {
      setState(() {
        _hasCameraPermission = false;
        _isInitializing = false;
        _cameraError = 'Camera initialization error: $e';
      });
    }
  }

  Future<void> _retryPermission() async {
    // If we already have a controller and permission, just try to start
    if (cameraController != null && _hasCameraPermission && !_isCameraStarted) {
      await _startCameraSafely();
    } else {
      // Otherwise, reinitialize everything
      await _initializeCamera();
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Debouncing: Skip if same code scanned within debounce window
    final now = DateTime.now();
    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < _debounceWindow) {
      return; // Ignore duplicate scan
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
      _lastScanTime = now;
    });

    try {
      // Mode: Capture barcode value only (for new product creation)
      if (widget.mode == BarcodeScannerMode.captureBarcode) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.pop(context, code);
          Fluttertoast.showToast(
            msg: 'বারকোড স্ক্যান সফল: $code',
            backgroundColor: ColorPalette.tealAccent,
            textColor: ColorPalette.white,
          );
        }
        return;
      }

      // Lookup product
      final product = await _barcodeService.findProductByBarcode(code);

      if (product == null) {
        // Product not found
        Fluttertoast.showToast(
          msg: 'Product not found for barcode: $code',
          backgroundColor: ColorPalette.mandy,
          textColor: ColorPalette.white,
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Mode: Fast Sale Session (multi-scan, stay on camera)
      if (widget.mode == BarcodeScannerMode.fastSaleSession) {
        setState(() {
          _foundProduct = product;
        });

        // Add or increment product in session
        if (_scannedItems.containsKey(product.id)) {
          _scannedItems[product.id]!.increment();
          Fluttertoast.showToast(
            msg: '${product.name} x${_scannedItems[product.id]!.quantity}',
            backgroundColor: ColorPalette.tealAccent,
            textColor: ColorPalette.white,
          );
        } else {
          _scannedItems[product.id!] = FastSaleScanItem(product: product);
          Fluttertoast.showToast(
            msg: 'Added ${product.name}',
            backgroundColor: ColorPalette.tealAccent,
            textColor: ColorPalette.white,
          );
        }

        // Reset processing after brief delay (keep camera active)
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _isProcessing = false;
          _foundProduct = null;
        });
        return;
      }

      // Mode: Lookup existing product (single scan, auto-return)
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

  /// Confirm and return scanned items (Fast Sale session mode)
  void _confirmScanSession() {
    if (_scannedItems.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No items scanned',
        backgroundColor: ColorPalette.mandy,
        textColor: ColorPalette.white,
      );
      return;
    }

    final result = FastSaleScanResult(items: Map.from(_scannedItems));
    Navigator.pop(context, result);
  }

  /// Discard scan session (with confirmation if items exist)
  void _cancelScanSession() {
    if (_scannedItems.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Discard scanned items?',
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        content: Text(
          '${_scannedItems.length} item(s) will be discarded',
          style: const TextStyle(fontFamily: 'Nunito'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close scanner
            },
            child: const Text(
              'Discard',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: ColorPalette.mandy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Remove item from scan session
  void _removeItem(String productId) {
    setState(() {
      _scannedItems.remove(productId);
    });
    Fluttertoast.showToast(
      msg: 'Item removed',
      backgroundColor: ColorPalette.gray400,
      textColor: ColorPalette.white,
    );
  }

  /// Increment item quantity
  void _incrementQuantity(String productId) {
    setState(() {
      _scannedItems[productId]?.increment();
    });
  }

  /// Decrement item quantity
  void _decrementQuantity(String productId) {
    setState(() {
      _scannedItems[productId]?.decrement();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview or error UI
            if (_isInitializing)
              _buildLoadingUI()
            else if (_cameraError != null || !_hasCameraPermission)
              _buildPermissionErrorUI()
            else if (cameraController != null)
              MobileScanner(
                controller: cameraController!,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) {
                  final errorMsg = error.toString();
                  // Don't show error UI for "already started" - it's handled gracefully
                  if (errorMsg.toLowerCase().contains('already started')) {
                    return child ?? const SizedBox.shrink();
                  }
                  return _buildCameraErrorUI(errorMsg);
                },
              ),

            // Top bar with controls
            if (_hasCameraPermission && cameraController != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.mode == BarcodeScannerMode.fastSaleSession
                            ? _cancelScanSession
                            : () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      // Confirm button for Fast Sale session mode
                      if (widget.mode == BarcodeScannerMode.fastSaleSession)
                        IconButton(
                          onPressed: _confirmScanSession,
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ColorPalette.tealAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: () async {
                          await cameraController!.toggleTorch();
                        },
                        icon: const Icon(
                          Icons.flashlight_on,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await cameraController!.switchCamera();
                        },
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),

            // Bottom scanning frame and instructions
            if (_hasCameraPermission && cameraController != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: widget.mode == BarcodeScannerMode.fastSaleSession
                    ? _buildFastSaleSessionPanel()
                    : _buildStandardScanningUI(),
              ),
          ],
        ),
      ),
    );
  }

  /// Standard scanning UI (scanning frame + instructions)
  Widget _buildStandardScanningUI() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: _foundProduct != null ? Colors.green : Colors.white,
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
                  Text(
                    widget.mode == BarcodeScannerMode.captureBarcode
                        ? 'বারকোড স্ক্যান করুন'
                        : 'Position barcode within frame',
                    style: const TextStyle(
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
    );
  }

  /// Fast Sale session panel (bottom sheet with scanned items)
  Widget _buildFastSaleSessionPanel() {
    final totalItems = _scannedItems.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final totalAmount = _scannedItems.values.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scanned Items',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalItems item(s) • ৳${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          // Scanned items list
          if (_scannedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scan barcodes to add items',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _scannedItems.length,
                separatorBuilder: (_, __) => const Divider(
                  color: Colors.white12,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = _scannedItems.values.elementAt(index);
                  final productId = _scannedItems.keys.elementAt(index);
                  return _buildScannedItemCard(item, productId);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Individual scanned item card
  Widget _buildScannedItemCard(FastSaleScanItem item, String productId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name ?? 'Unknown',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '৳${(item.product.salePrice ?? item.product.cost ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _decrementQuantity(productId),
                  icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _incrementQuantity(productId),
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Remove button
          IconButton(
            onPressed: () => _removeItem(productId),
            icon: const Icon(Icons.close, color: ColorPalette.mandy, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: ColorPalette.tealAccent,
          ),
          const SizedBox(height: 24),
          Text(
            widget.mode == BarcodeScannerMode.captureBarcode
                ? 'ক্যামেরা চালু করা হচ্ছে...'
                : 'Initializing camera...',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionErrorUI() {
    final isPermanentlyDenied = _cameraError?.contains('permanently') ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: ColorPalette.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              widget.mode == BarcodeScannerMode.captureBarcode
                  ? 'ক্যামেরা অনুমতি প্রয়োজন'
                  : 'Camera Permission Required',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              widget.mode == BarcodeScannerMode.captureBarcode
                  ? 'বারকোড স্ক্যান করার জন্য ক্যামেরা অ্যাক্সেস করতে হবে'
                  : 'This app needs camera access to scan barcodes',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isPermanentlyDenied)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: Text(
                    widget.mode == BarcodeScannerMode.captureBarcode
                        ? 'সেটিংস খুলুন'
                        : 'Open Settings',
                    style: const TextStyle(fontFamily: 'Nunito'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.tealAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _retryPermission,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    widget.mode == BarcodeScannerMode.captureBarcode
                        ? 'আবার চেষ্টা করুন'
                        : 'Retry',
                    style: const TextStyle(fontFamily: 'Nunito'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.tealAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (!isPermanentlyDenied) const SizedBox(height: 12),
            if (!isPermanentlyDenied)
              TextButton(
                onPressed: _openAppSettings,
                child: Text(
                  widget.mode == BarcodeScannerMode.captureBarcode
                      ? 'সেটিংস খুলুন'
                      : 'Open Settings',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraErrorUI(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: ColorPalette.mandy,
            ),
            const SizedBox(height: 24),
            Text(
              widget.mode == BarcodeScannerMode.captureBarcode
                  ? 'ক্যামেরা এরর'
                  : 'Camera Error',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _retryPermission,
              icon: const Icon(Icons.refresh),
              label: Text(
                widget.mode == BarcodeScannerMode.captureBarcode
                    ? 'আবার চেষ্টা করুন'
                    : 'Retry',
                style: const TextStyle(fontFamily: 'Nunito'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.tealAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
