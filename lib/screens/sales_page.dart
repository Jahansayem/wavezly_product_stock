import 'package:flutter/material.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/cart_item.dart';
import 'package:warehouse_management/models/sale.dart';
import 'package:warehouse_management/services/product_service.dart';
import 'package:warehouse_management/services/sales_service.dart';
import 'package:warehouse_management/widgets/barcode_scan_card.dart';
import 'package:warehouse_management/widgets/cart_item_card.dart';
import 'package:warehouse_management/widgets/customer_selector.dart';
import 'package:warehouse_management/screens/barcode_scanner_screen.dart';
import 'package:warehouse_management/screens/receipt_page.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final List<CartItem> _cartItems = [];
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final SalesService _salesService = SalesService();
  String _customerName = 'Walk-in Customer';
  List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _isProcessingSale = false;

  double get _subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _taxAmount => _subtotal * 0.18;
  double get _totalAmount => _subtotal + _taxAmount;
  int get _totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }

      _searchController.clear();
      _searchResults.clear();
      _isSearching = false;
    });

    Fluttertoast.showToast(
      msg: 'Added ${product.name} to cart',
      backgroundColor: ColorPalette.pacificBlue,
      textColor: ColorPalette.white,
    );
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      _cartItems.remove(item);
    });
  }

  void _incrementQuantity(CartItem item) {
    setState(() {
      item.quantity++;
    });
  }

  void _decrementQuantity(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _removeFromCart(item);
      }
    });
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _productService.searchProducts(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error searching products: $e',
        backgroundColor: ColorPalette.mandy,
        textColor: ColorPalette.white,
      );
    }
  }

  Future<void> _confirmCharge() async {
    if (_cartItems.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Cart is empty',
        backgroundColor: ColorPalette.mandy,
        textColor: ColorPalette.white,
      );
      return;
    }

    setState(() {
      _isProcessingSale = true;
    });

    try {
      final sale = Sale(
        subtotal: _subtotal,
        taxAmount: _taxAmount,
        totalAmount: _totalAmount,
        customerName: _customerName,
        paymentMethod: 'cash',
      );

      final saleId = await _salesService.processSale(sale, _cartItems);

      final completedSale = await _salesService.getSaleById(saleId);
      final saleItems = await _salesService.getSaleItems(saleId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptPage(
              sale: completedSale,
              saleItems: saleItems,
            ),
          ),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error processing sale: $e',
        backgroundColor: ColorPalette.mandy,
        textColor: ColorPalette.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingSale = false;
        });
      }
    }
  }

  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null) {
      _addToCart(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              decoration: const BoxDecoration(
                color: ColorPalette.pacificBlue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: ColorPalette.white,
                      size: 32,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    "Log New Sale",
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.help_outline,
                      color: ColorPalette.white,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('POS Help'),
                          content: const Text(
                            'Scan barcodes or search products to add to cart.\n\n'
                            'Adjust quantities with +/- buttons.\n\n'
                            'Select customer and confirm charge when ready.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  BarcodeScanCard(),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorPalette.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search products...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: ColorPalette.nileBlue,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                color: ColorPalette.timberGreen,
                              ),
                              onChanged: _searchProducts,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomerSelector(
                          customerName: _customerName,
                          onCustomerChanged: (name) {
                            setState(() {
                              _customerName = name;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_isSearching && _searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: ColorPalette.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return ListTile(
                            title: Text(
                              product.name ?? 'Unknown',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: ColorPalette.timberGreen,
                              ),
                            ),
                            subtitle: Text(
                              currencyFormatter.format(product.cost ?? 0),
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: ColorPalette.nileBlue,
                              ),
                            ),
                            trailing: Text(
                              'Stock: ${product.quantity ?? 0}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: ColorPalette.nileBlue,
                              ),
                            ),
                            onTap: () => _addToCart(product),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Current Cart',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ColorPalette.timberGreen,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_cartItems.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorPalette.pacificBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_totalItems items',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ColorPalette.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _cartItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 64,
                                        color: ColorPalette.nileBlue.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Cart is empty',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 18,
                                          color: ColorPalette.nileBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Scan or search products to add',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 14,
                                          color: ColorPalette.nileBlue.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _cartItems.length,
                                  itemBuilder: (context, index) {
                                    final cartItem = _cartItems[index];
                                    return CartItemCard(
                                      cartItem: cartItem,
                                      onIncrement: () => _incrementQuantity(cartItem),
                                      onDecrement: () => _decrementQuantity(cartItem),
                                      onRemove: () => _removeFromCart(cartItem),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorPalette.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Due',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              color: ColorPalette.nileBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.format(_totalAmount),
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.pacificBlue,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.pacificBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tax Incl.',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.pacificBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cart: $_totalItems items',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: ColorPalette.nileBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cartItems.isEmpty || _isProcessingSale
                          ? null
                          : _confirmCharge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.pacificBlue,
                        foregroundColor: ColorPalette.white,
                        disabledBackgroundColor: ColorPalette.nileBlue.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessingSale
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorPalette.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Confirm Charge',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
