import 'package:flutter/material.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/services/product_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/product_card.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({Key? key}) : super(key: key);

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final ProductService _productService = ProductService();
  FocusNode? inputFieldNode;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    inputFieldNode = FocusNode();
  }

  @override
  void dispose() {
    inputFieldNode!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: ColorPalette.pacificBlue,
        child: SafeArea(
          child: Container(
            color: ColorPalette.aquaHaze,
            height: double.infinity,
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    top: 10,
                    left: 10,
                    right: 15,
                  ),
                  width: double.infinity,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: ColorPalette.pacificBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 35,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      Expanded(
                        child: TextFormField(
                          focusNode: inputFieldNode,
                          autofocus: true,
                          initialValue: searchQuery,
                          onFieldSubmitted: (value) {
                            setState(() {
                              searchQuery = value;
                              FocusScope.of(context)
                                  .requestFocus(inputFieldNode);
                            });
                          },
                          textInputAction: TextInputAction.search,
                          key: UniqueKey(),
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 24,
                            color: ColorPalette.timberGreen,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Product Name",
                            filled: true,
                            fillColor: Colors.transparent,
                            hintStyle: TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 24,
                              color: ColorPalette.timberGreen.withOpacity(0.58),
                            ),
                          ),
                          cursorColor: ColorPalette.timberGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Expanded(
                            child: searchQuery.isEmpty
                                ? const SizedBox()
                                : FutureBuilder<List<Product>>(
                                    future: _productService
                                        .searchProducts(searchQuery),
                                    builder: (
                                      BuildContext context,
                                      AsyncSnapshot<List<Product>> snapshot,
                                    ) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(
                                          child: SizedBox(
                                            height: 40,
                                            width: 40,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                            ),
                                          ),
                                        );
                                      }
                                      if (!snapshot.hasData) {
                                        return const SizedBox();
                                      }
                                      final products = snapshot.data!;
                                      if (products.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No products found',
                                            style: TextStyle(
                                              fontFamily: "Nunito",
                                              fontSize: 16,
                                              color: ColorPalette.nileBlue,
                                            ),
                                          ),
                                        );
                                      }
                                      return ListView.builder(
                                        itemCount: products.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return ProductCard(
                                            product: products[index],
                                            docID: products[index].id!,
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
