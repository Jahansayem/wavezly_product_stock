import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavezly/screens/splash/shopstock_splash.dart';
import 'package:wavezly/utils/color_palette.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
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
