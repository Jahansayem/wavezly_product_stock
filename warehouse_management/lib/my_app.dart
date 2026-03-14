import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wavezly/localization/app_locale_controller.dart';
import 'package:wavezly/localization/app_strings.dart';
import 'package:wavezly/screens/splash/shopstock_splash.dart';
import 'package:wavezly/utils/color_palette.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global navigator key for deep linking
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return AnimatedBuilder(
      animation: AppLocaleController.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppStrings.of(context).appTitle,
          locale: AppLocaleController.instance.locale,
          supportedLocales: AppLocaleController.supportedLocales,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSwatch()
                .copyWith(secondary: ColorPalette.white),
          ),
          home: const ShopStockSplash(),
        );
      },
    );
  }
}
