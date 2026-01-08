import 'package:flutter/material.dart';
import 'package:warehouse_management/functions/confirm_dialog.dart';
import 'package:warehouse_management/functions/toast.dart';
import 'package:warehouse_management/screens/global_search_page.dart';
import 'package:warehouse_management/services/auth_service.dart';
import 'package:warehouse_management/services/product_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/product_group_card.dart';

class StockPage extends StatelessWidget {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final TextEditingController _newProductGroup = TextEditingController();

  StockPage({Key? key}) : super(key: key);

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
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text(
                    "Add Product Group",
                    style: TextStyle(fontFamily: "Nunito"),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: ColorPalette.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                              color: const Color(0xff000000).withOpacity(0.16),
                            ),
                          ],
                        ),
                        height: 50,
                        child: TextField(
                          textInputAction: TextInputAction.next,
                          key: UniqueKey(),
                          controller: _newProductGroup,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 16,
                            color: ColorPalette.nileBlue,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Product Group Name",
                            filled: true,
                            fillColor: Colors.transparent,
                            hintStyle: TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 16,
                              color: ColorPalette.nileBlue.withOpacity(0.58),
                            ),
                          ),
                          cursorColor: ColorPalette.timberGreen,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (_newProductGroup.text.isNotEmpty) {
                            try {
                              await _productService
                                  .addProductGroup(_newProductGroup.text);
                              showTextToast("Added Successfully");
                            } catch (e) {
                              if (e.toString().contains('duplicate')) {
                                showTextToast("Group Name already exists");
                              } else {
                                showTextToast("An Error Occurred!");
                              }
                            }
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();
                            _newProductGroup.text = "";
                          } else {
                            showTextToast("Enter Valid Name!");
                          }
                        },
                        child: Container(
                          height: 45,
                          width: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: ColorPalette.pacificBlue,
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 3),
                                blurRadius: 6,
                                color:
                                    const Color(0xff000000).withOpacity(0.16),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Done",
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: "Nunito",
                                color: ColorPalette.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                    left: 20,
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
                      const Text(
                        "Stock",
                        style: TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 28,
                          color: ColorPalette.timberGreen,
                        ),
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
                                      const GlobalSearchPage(),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.power_settings_new,
                              color: ColorPalette.timberGreen,
                            ),
                            onPressed: () {
                              showConfirmDialog(
                                  context,
                                  "Are you sure you want to Logout?",
                                  "No",
                                  "Yes", () {
                                Navigator.of(context).pop();
                              }, () {
                                Navigator.of(context).pop();
                                _authService.signOut();
                              });
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
                            "Product Groups",
                            style: TextStyle(
                              color: ColorPalette.timberGreen,
                              fontSize: 20,
                              fontFamily: "Nunito",
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: StreamBuilder<List<String>>(
                              stream: _productService.getProductGroupsStream(),
                              builder: (
                                BuildContext context,
                                AsyncSnapshot<List<String>> snapshot,
                              ) {
                                if (snapshot.hasData) {
                                  final List<String> _productGroups =
                                      snapshot.data!;
                                  if (_productGroups.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'No product groups yet.\nTap + to add one!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: "Nunito",
                                          fontSize: 16,
                                          color: ColorPalette.nileBlue,
                                        ),
                                      ),
                                    );
                                  }
                                  return GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 2,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                    ),
                                    itemCount: _productGroups.length,
                                    itemBuilder: (context, index) {
                                      return ProductGroupCard(
                                        name: _productGroups[index],
                                        key: UniqueKey(),
                                      );
                                    },
                                  );
                                } else {
                                  return const Center(
                                    child: SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: CircularProgressIndicator(
                                        color: ColorPalette.pacificBlue,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          )
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
