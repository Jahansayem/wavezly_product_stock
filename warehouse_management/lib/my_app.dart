import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavezly/screens/splash/shopstock_splash.dart';
import 'package:wavezly/utils/color_palette.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global navigator key for deep linking
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Halkhata',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: ColorPalette.white),
      ),
      home: const ShopStockSplash(),
    );
  }
}
