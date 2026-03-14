import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    assert(strings != null, 'AppStrings not found in context');
    return strings!;
  }

  bool get isEnglish => locale.languageCode == 'en';

  String _text(String bangla, String english) {
    return isEnglish ? english : bangla;
  }

  String get appTitle => 'Halkhata';
  String get settingsTitle => _text('সেটিংস', 'Settings');
  String get appSettingsSection => _text('অ্যাপ সেটিংস', 'App settings');
  String get otherSection => _text('অন্যান্য', 'Other');
  String get edit => _text('এডিট করুন', 'Edit');
  String get logout => _text('লগ আউট', 'Log out');
  String get loggingOut => _text('লগআউট হচ্ছে...', 'Logging out...');

  String get userFallbackName => _text('হালখাতা ব্যবহারকারী', 'Halkhata user');
  String get phoneNotAdded =>
      _text('ফোন নম্বর যোগ করা হয়নি', 'Phone number not added');
  String get profileLoadFailed => _text(
      'প্রোফাইল তথ্য লোড করা যায়নি।', 'Could not load profile information.');
  String get profileNotReady => _text(
        'প্রোফাইল তথ্য এখনো প্রস্তুত নয়।',
        'Profile information is not ready yet.',
      );
  String get profileStatus => _text('প্রোফাইল স্ট্যাটাস:', 'Profile status:');
  String get completeProfileForCard => _text(
        'ফ্রি বিজনেস কার্ড পেতে প্রোফাইল তথ্য ১০০% সম্পূর্ণ করুন',
        'Complete your profile to 100% to get a free business card.',
      );

  String get subscription => _text('সাবস্ক্রিপশন', 'Subscription');
  String get subscriptionPending =>
      _text('তথ্য শীঘ্রই যুক্ত হবে', 'Details will be added soon');
  String get subscriptionDetail => _text(
        'AI ক্রেডিট, SMS এবং প্যাকেজ তথ্য এখানে দেখানো হবে।',
        'AI credits, SMS, and package details will appear here.',
      );
  String get switchShop => _text('দোকান পরিবর্তন করুন', 'Switch shop');

  String get halkhataAppSettings =>
      _text('হিসাবী অ্যাপ সেটিংস', 'Halkhata app settings');
  String get appSettings => _text('অ্যাপ সেটিংস', 'App settings');
  String get cashCounter => _text('ক্যাশ কাউন্টার', 'Cash counter');
  String get webApp => _text('হিসাবী ওয়েব অ্যাপ', 'Halkhata web app');
  String get appTraining => _text('অ্যাপ ট্রেনিং', 'App training');
  String get language => _text('ভাষা', 'Language');
  String get currency => _text('কারেন্সি', 'Currency');
  String get businessCard => _text('বিজনেস কার্ড', 'Business card');
  String get addShortcut => _text('শর্টকাট এড করুন', 'Add shortcut');
  String get appTrainingComingSoon => _text('অ্যাপ ট্রেনিং', 'App training');

  String get bkashNagadQr => _text('বিকাশ/নগদ কিউ আর', 'bKash/Nagad QR');
  String get customCategory => _text('কাস্টম ক্যাটাগরি', 'Custom category');
  String get decimalPoint => _text('দশমিক পয়েন্ট', 'Decimal point');
  String get dataBackup => _text('ডাটা ব্যাকআপ', 'Data backup');
  String get recycleBin => _text('রিসাইকেল বিন', 'Recycle bin');
  String get appLock => _text('অ্যাপ লক', 'App lock');
  String get dataDownload => _text('ডাটা ডাউনলোড', 'Data download');
  String get dataDownloadSubtitle =>
      _text('অ্যাপের সকল তথ্য ডাউনলোড', 'Download all app data');
  String get appReset => _text('অ্যাপ রিসেট', 'App reset');
  String get appResetSubtitle => _text(
        'রিসেট করলে অ্যাপের সকল তথ্য মুছে যাবে',
        'Resetting will erase all app data.',
      );

  String get featureRequest => _text('ফিচার অনুরোধ', 'Feature request');
  String get growthPartner =>
      _text('হিসাবী গ্রোথ পার্টনার', 'Halkhata growth partner');
  String get facebookCommunity =>
      _text('ফেসবুক কমিউনিটি', 'Facebook community');

  String get languageSheetTitle => _text('অ্যাপের ভাষা', 'App language');
  String get languageSheetSubtitle =>
      _text('English বা বাংলা বেছে নিন', 'Choose English or বাংলা');
  String get english => 'English';
  String get bangla => 'বাংলা';
  String get englishShort => 'Eng';
  String get banglaShort => 'বাং';
  String currentLanguageLabel(String languageCode) {
    return languageCode == 'en' ? english : bangla;
  }

  String get loginTitle => _text('আপনার হালখাতা অ্যাকাউন্টে\nলগ ইন করুন',
      'Log in to your Halkhata\naccount');
  String get mobileNumberLabel => _text('মোবাইল নম্বর', 'Mobile number');
  String get mobileNumberHint => _text('মোবাইল নং', 'Mobile no.');
  String get continueText => _text('এগিয়ে যান', 'Continue');
  String get helpline => _text('হেল্প লাইন', 'Helpline');
  String get securityBanner => _text(
        'আপনার তথ্য থাকবে ১০০% সুরক্ষিত',
        'Your information stays 100% secure',
      );
  String get invalidPhoneFormat => _text(
        'সঠিক মোবাইল নম্বর দিন (01XXXXXXXXX)',
        'Enter a valid mobile number (01XXXXXXXXX)',
      );
  String get genericRetryError => _text('সমস্যা হয়েছে। আবার চেষ্টা করুন',
      'Something went wrong. Please try again.');
  String get helplineTapped =>
      _text('হেল্প লাইন চাপা হয়েছে', 'Helpline tapped');

  String comingSoon(String label) {
    return isEnglish ? '$label coming soon.' : '$label শীঘ্রই যুক্ত হবে।';
  }

  String get cashCounterLiveUpdated => _text(
        'ক্যাশ কাউন্টার হিসাব লাইভ আপডেট হয়।',
        'Cash counter totals update live.',
      );
  String get cashCounterHistoryLater => _text(
        'ক্যাশ কাউন্টার হিস্ট্রি পরে যোগ হবে।',
        'Cash counter history will be added later.',
      );

  String get appLockEnabledMessage =>
      _text('অ্যাপ লক চালু করা হয়েছে।', 'App lock enabled.');
  String get appLockDisabledMessage =>
      _text('অ্যাপ লক বন্ধ করা হয়েছে।', 'App lock disabled.');
  String get appLockSaveFailed => _text(
        'অ্যাপ লক সেটিংস সংরক্ষণ করা যায়নি।',
        'Could not save the app lock setting.',
      );

  String get backupInProgress => _text(
        'ডাটা ব্যাকআপ চলছে। অনুগ্রহ করে অপেক্ষা করুন।',
        'Data backup is already running. Please wait.',
      );
  String get backupOffline => _text(
        'ইন্টারনেট সংযোগ ছাড়া ব্যাকআপ করা যাবে না।',
        'Backup requires an internet connection.',
      );
  String get backupFailed => _text(
      'ডাটা ব্যাকআপ সম্পন্ন করা যায়নি।', 'Could not complete data backup.');
  String backupSuccessCount(int count) {
    return isEnglish
        ? 'Data backup complete. Synced $count records.'
        : 'ডাটা ব্যাকআপ সম্পন্ন হয়েছে। $count টি রেকর্ড সিঙ্ক হয়েছে।';
  }

  String get backupSuccessNoChanges => _text(
        'ডাটা ব্যাকআপ সম্পন্ন হয়েছে। নতুন কোনো পরিবর্তন ছিল না।',
        'Data backup complete. No new changes were found.',
      );

  String get resetConfirmation => _text(
        'অ্যাপ রিসেট করলে আপনার সকল লোকাল ডাটা মুছে যেতে পারে। আপনি কি নিশ্চিত?',
        'Resetting the app may erase all local data. Are you sure?',
      );
  String get no => _text('না', 'No');
  String get yes => _text('হ্যাঁ', 'Yes');
  String get reset => _text('রিসেট', 'Reset');
  String get appResetNotAvailable => _text(
        'অ্যাপ রিসেট এখনো চালু হয়নি। পরে যুক্ত করা হবে।',
        'App reset is not available yet. It will be added later.',
      );

  String get logoutConfirmation =>
      _text('আপনি কি লগআউট করতে চান?', 'Do you want to log out?');
  String get logoutTimeout => _text(
        'লগআউট সময় শেষ হয়েছে। আবার চেষ্টা করুন।',
        'Logout timed out. Please try again.',
      );
  String get logoutFailed => _text('লগআউট করা যায়নি। আবার চেষ্টা করুন।',
      'Could not log out. Please try again.');
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'bn' || locale.languageCode == 'en';
  }

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture<AppStrings>(AppStrings(locale));
  }

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
