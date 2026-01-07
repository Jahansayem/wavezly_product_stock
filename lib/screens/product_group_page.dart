import 'package:flutter/material.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/screens/new_product_page.dart';
import 'package:warehouse_management/screens/search_product_in_group.dart';
import 'package:warehouse_management/services/product_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/product_card.dart';

class ProductGroupPage extends StatelessWidget {
  final String? name;
  ProductGroupPage({Key? key, this.name}) : super(key: key);

  final ProductService _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
          right: 10,
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return NewProductPage(
                    group: name,
                  );
                },
              ),
            );
          },
          splashColor: ColorPalette.bondyBlue,
          backgroundColor: ColorPalette.pacificBlue,
          child: const Icon(
            Icons.add,
            color: ColorPalette.white,
          ),
        ),
      ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                          Text(
                            name!.length > 14
                                ? '${name!.substring(0, 12)}..'
                                : name!,
                            style: const TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 28,
                              color: ColorPalette.timberGreen,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            splashColor: ColorPalette.timberGreen,
                            icon: const Icon(
                              Icons.search,
                              color: ColorPalette.timberGreen,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SearchProductInGroupPage(
                                    name: name,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: ColorPalette.timberGreen,
                            ),
                            onPressed: () {
                              //TODO
                            },
                          ),
                        ],
                      )
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
                          Row(
                            children: const [
                              SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                          const Text(
                            "Products",
                            style: TextStyle(
                              color: ColorPalette.timberGreen,
                              fontSize: 20,
                              fontFamily: "Nunito",
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: StreamBuilder<List<Product>>(
                              stream:
                                  _productService.getProductsByGroup(name!),
                              builder: (
                                BuildContext context,
                                AsyncSnapshot<List<Product>> snapshot,
                              ) {
                                if (!snapshot.hasData) {
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
                                final products = snapshot.data!;
                                if (products.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No products yet.\nTap + to add one!',
                                      textAlign: TextAlign.center,
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
