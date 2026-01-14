import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/services/auth_service.dart';
import 'package:wavezly/screens/register.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/utils/svg_strings.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _failed = false;
  bool _isVisible = false;
  bool _loading = false;

  Future signIn() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      showTextToast('Logged In Successfully!');
    } catch (e) {
      setState(() {
        _failed = true;
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
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              SvgPicture.string(SvgStrings.warehouse),
              const SizedBox(
                height: 18,
              ),
              const Text(
                "Inventory Management",
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 40,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  SvgPicture.string(SvgStrings.location),
                  const SizedBox(
                    width: 10,
                  ),
                  const Expanded(
                    child: Text(
                      "Manage your inventory Smartly",
                      style: TextStyle(fontFamily: "Open_Sans", fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 50,
              ),
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
              const SizedBox(
                height: 20,
              ),
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
                        obscureText: !_isVisible,
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
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
                        color: _isVisible ? Colors.black : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isVisible = !_isVisible;
                        });
                      },
                      splashColor: Colors.transparent,
                      splashRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Center(
                child: Text(
                  _failed ? "Enter valid credentials!" : "",
                  style: const TextStyle(
                    color: ColorPalette.mandy,
                    fontFamily: "Nunito",
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await signIn();
                    },
                    child: Container(
                      height: 50,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: ColorPalette.tealAccent,
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
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Login",
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 14,
                      color: ColorPalette.nileBlue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Register()),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontFamily: "Nunito",
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.tealAccent,
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
