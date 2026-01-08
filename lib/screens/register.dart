import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/services/auth_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/utils/svg_strings.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  String _errorMessage = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _loading = false;

  Future<void> signUp() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    // Validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
        _loading = false;
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _loading = false;
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
        _loading = false;
      });
      return;
    }

    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
      showTextToast('Account created successfully!');
      // Navigation will happen automatically via auth state change
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: ColorPalette.aquaHaze,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.nileBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            SvgPicture.string(SvgStrings.warehouse),
            const SizedBox(height: 18),
            const Text(
              "Create\nAccount",
              style: TextStyle(
                fontFamily: "Nunito",
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                SvgPicture.string(SvgStrings.location),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Manage your inventory Smartly",
                    style: TextStyle(fontFamily: "Open_Sans", fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            // Email field
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 16,
                  color: ColorPalette.nileBlue,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Email",
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
            // Password field
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      obscureText: !_isPasswordVisible,
                      controller: _passwordController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.visiblePassword,
                      style: const TextStyle(
                        fontFamily: "Nunito",
                        fontSize: 16,
                        color: ColorPalette.nileBlue,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Password",
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
                  IconButton(
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: _isPasswordVisible ? Colors.black : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    splashColor: Colors.transparent,
                    splashRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Confirm Password field
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      obscureText: !_isConfirmPasswordVisible,
                      controller: _confirmPasswordController,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.visiblePassword,
                      style: const TextStyle(
                        fontFamily: "Nunito",
                        fontSize: 16,
                        color: ColorPalette.nileBlue,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Confirm Password",
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
                  IconButton(
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: _isConfirmPasswordVisible
                          ? Colors.black
                          : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    splashColor: Colors.transparent,
                    splashRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            // Error message
            Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: ColorPalette.mandy,
                  fontFamily: "Nunito",
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            // Sign Up button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    await signUp();
                  },
                  child: Container(
                    height: 50,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: ColorPalette.pacificBlue,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                          color: const Color(0xff000000).withOpacity(0.16),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorPalette.aquaHaze,
                              ),
                            )
                          : const Text(
                              "Sign Up",
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
            const SizedBox(height: 20),
            // Already have account
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account? ",
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 14,
                    color: ColorPalette.nileBlue,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.pacificBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
          ),
        ),
      ),
      ),
    );
  }
}
