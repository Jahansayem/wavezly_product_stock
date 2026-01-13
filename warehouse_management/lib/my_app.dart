import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wavezly/screens/main_navigation.dart';
import 'package:wavezly/screens/login.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/sync/sync_service.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warehouse Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: ColorPalette.white),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.hasData &&
              snapshot.data!.session != null &&
              snapshot.data!.session!.user != null) {
            // User authenticated - trigger initial sync
            print('User authenticated, triggering sync...');
            SyncService().syncNow();
            return const MainNavigation();
          } else {
            return Login();
          }
        },
      ),
    );
  }
}
