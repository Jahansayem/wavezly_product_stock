import 'package:flutter/material.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/services/customer_service.dart';
import 'package:wavezly/utils/color_palette.dart';

class NewCustomerPage extends StatefulWidget {
  const NewCustomerPage({Key? key}) : super(key: key);

  @override
  _NewCustomerPageState createState() => _NewCustomerPageState();
}

class _NewCustomerPageState extends State<NewCustomerPage> {
  final Customer newCustomer = Customer();
  final CustomerService _customerService = CustomerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
          right: 10,
        ),
        child: FloatingActionButton(
          onPressed: () async {
            // Validate required fields
            if (newCustomer.name == null || newCustomer.name!.isEmpty) {
              showTextToast('Please enter customer name');
              return;
            }
            if (newCustomer.phone == null || newCustomer.phone!.isEmpty) {
              showTextToast('Please enter phone number');
              return;
            }

            try {
              await _customerService.createCustomer(newCustomer);
              showTextToast('Customer added successfully!');
              Navigator.of(context).pop();
            } catch (e) {
              showTextToast('Failed to add customer!');
            }
          },
          splashColor: ColorPalette.bondyBlue,
          backgroundColor: ColorPalette.pacificBlue,
          child: const Icon(
            Icons.done,
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
                          const Text(
                            "New Customer",
                            style: TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 28,
                              color: ColorPalette.timberGreen,
                            ),
                          ),
                        ],
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
                          Row(
                            children: const [
                              SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                          Expanded(
                            child: Container(
                              height: double.infinity,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 30,
                              ),
                              decoration: const BoxDecoration(
                                color: ColorPalette.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Customer Name
                                    Container(
                                      decoration: BoxDecoration(
                                        color: ColorPalette.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: const Offset(0, 3),
                                            blurRadius: 6,
                                            color: ColorPalette.nileBlue.withOpacity(0.1),
                                          ),
                                        ],
                                      ),
                                      height: 50,
                                      child: TextFormField(
                                        initialValue: newCustomer.name ?? '',
                                        onChanged: (value) {
                                          newCustomer.name = value;
                                        },
                                        textInputAction: TextInputAction.next,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.text,
                                        style: const TextStyle(
                                          fontFamily: "Nunito",
                                          fontSize: 16,
                                          color: ColorPalette.nileBlue,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Customer Name *",
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
                                    const SizedBox(height: 20),

                                    // Phone Number
                                    Container(
                                      decoration: BoxDecoration(
                                        color: ColorPalette.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: const Offset(0, 3),
                                            blurRadius: 6,
                                            color: ColorPalette.nileBlue.withOpacity(0.1),
                                          ),
                                        ],
                                      ),
                                      height: 50,
                                      child: TextFormField(
                                        initialValue: newCustomer.phone ?? '',
                                        onChanged: (value) {
                                          newCustomer.phone = value;
                                        },
                                        textInputAction: TextInputAction.next,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.phone,
                                        style: const TextStyle(
                                          fontFamily: "Nunito",
                                          fontSize: 16,
                                          color: ColorPalette.nileBlue,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Phone Number *",
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
                                    const SizedBox(height: 20),

                                    // Customer Type Dropdown
                                    Container(
                                      decoration: BoxDecoration(
                                        color: ColorPalette.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: const Offset(0, 3),
                                            blurRadius: 6,
                                            color: ColorPalette.nileBlue.withOpacity(0.1),
                                          ),
                                        ],
                                      ),
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: DropdownButtonFormField<String>(
                                        value: newCustomer.customerType,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Customer Type",
                                        ),
                                        style: const TextStyle(
                                          fontFamily: "Nunito",
                                          fontSize: 16,
                                          color: ColorPalette.nileBlue,
                                        ),
                                        dropdownColor: ColorPalette.white,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'customer',
                                            child: Text('Customer'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'employee',
                                            child: Text('Employee'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'supplier',
                                            child: Text('Supplier'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            newCustomer.customerType = value ?? 'customer';
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Email (Optional)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: ColorPalette.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: const Offset(0, 3),
                                            blurRadius: 6,
                                            color: ColorPalette.nileBlue.withOpacity(0.1),
                                          ),
                                        ],
                                      ),
                                      height: 50,
                                      child: TextFormField(
                                        initialValue: newCustomer.email ?? '',
                                        onChanged: (value) {
                                          newCustomer.email = value;
                                        },
                                        textInputAction: TextInputAction.next,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.emailAddress,
                                        style: const TextStyle(
                                          fontFamily: "Nunito",
                                          fontSize: 16,
                                          color: ColorPalette.nileBlue,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Email (optional)",
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
                                    const SizedBox(height: 20),

                                    // Address (Optional)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: ColorPalette.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: const Offset(0, 3),
                                            blurRadius: 6,
                                            color: ColorPalette.nileBlue.withOpacity(0.1),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: TextFormField(
                                        initialValue: newCustomer.address ?? '',
                                        onChanged: (value) {
                                          newCustomer.address = value;
                                        },
                                        textInputAction: TextInputAction.next,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.multiline,
                                        maxLines: 3,
                                        style: const TextStyle(
                                          fontFamily: "Nunito",
                                          fontSize: 16,
                                          color: ColorPalette.nileBlue,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Address (optional)",
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          hintStyle: TextStyle(
                                            fontFamily: "Nunito",
                                            fontSize: 16,
                                            color: ColorPalette.nileBlue.withOpacity(0.58),
                                          ),
                                        ),
                                        cursorColor: ColorPalette.timberGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Notes (Optional)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: ColorPalette.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: const Offset(0, 3),
                                            blurRadius: 6,
                                            color: ColorPalette.nileBlue.withOpacity(0.1),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: TextFormField(
                                        initialValue: newCustomer.notes ?? '',
                                        onChanged: (value) {
                                          newCustomer.notes = value;
                                        },
                                        textInputAction: TextInputAction.done,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.multiline,
                                        maxLines: 3,
                                        style: const TextStyle(
                                          fontFamily: "Nunito",
                                          fontSize: 16,
                                          color: ColorPalette.nileBlue,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Notes (optional)",
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          hintStyle: TextStyle(
                                            fontFamily: "Nunito",
                                            fontSize: 16,
                                            color: ColorPalette.nileBlue.withOpacity(0.58),
                                          ),
                                        ),
                                        cursorColor: ColorPalette.timberGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 100),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
