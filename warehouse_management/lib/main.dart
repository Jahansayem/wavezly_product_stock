import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavezly/config/database_config.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/sync/connectivity_service.dart';
import 'package:wavezly/sync/sync_service.dart';
import 'package:wavezly/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database FIRST (for offline support)
  print('Initializing local database...');
  await DatabaseConfig.initialize();

  // Initialize Supabase
  print('Initializing Supabase...');
  await SupabaseConfig.initialize();

  // Initialize connectivity monitoring
  print('Initializing connectivity service...');
  await ConnectivityService().initialize();

  // Start background sync service
  print('Starting sync service...');
  SyncService().startPeriodicSync();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  print('App initialization complete');
  runApp(MyApp());
}

//TODO Text overflow right way
//TODO Confirm delete in product delete
//TODO Font case in searching
