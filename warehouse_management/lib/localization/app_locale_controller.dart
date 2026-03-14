import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wavezly/config/database_config.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  static const String _languageSettingKey = 'app_language';
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  Locale _locale = supportedLocales.first;
  bool _initialized = false;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isBangla => languageCode == 'bn';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final savedCode = await _readLanguageCode();
    _locale = _localeFromCode(savedCode);
    _initialized = true;
  }

  Future<void> setLanguageCode(String languageCode) async {
    final nextLocale = _localeFromCode(languageCode);
    if (nextLocale.languageCode == _locale.languageCode) {
      return;
    }

    final previousLocale = _locale;
    _locale = nextLocale;
    notifyListeners();

    try {
      await _writeLanguageCode(nextLocale.languageCode);
    } catch (_) {
      _locale = previousLocale;
      notifyListeners();
      rethrow;
    }
  }

  String displayNameFor(String languageCode) {
    return languageCode == 'en' ? 'English' : 'বাংলা';
  }

  Locale _localeFromCode(String? languageCode) {
    if (languageCode == 'en') {
      return const Locale('en');
    }
    return const Locale('bn');
  }

  Future<String?> _readLanguageCode() async {
    final db = DatabaseConfig.database;
    final result = await db.query(
      'app_settings',
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object>[_languageSettingKey],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }
    return result.first['value'] as String?;
  }

  Future<void> _writeLanguageCode(String languageCode) async {
    final db = DatabaseConfig.database;
    await db.insert(
      'app_settings',
      <String, Object>{
        'key': _languageSettingKey,
        'value': languageCode,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
