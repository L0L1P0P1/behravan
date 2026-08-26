import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _translations = {
    'fa': {
      'appTitle': 'بهرavan',
      'voidingTab': 'ادرار',
      'enuresisTab': 'شب‌ادراری',
      'bowelTab': 'مدفوع',
      'reportsTab': 'گزارش',
      'voidingSchedule': 'برنامه زمان‌بندی ادرار',
      'quickVoidingLogger': 'ثبت سریع ادرار',
      'eventType': 'نوع رویداد',
      'promptedSuccess': 'موفق (یادآوری)',
      'spontaneous': 'خودبه‌خودی',
      'accident': 'تصادفی',
      'urgencyLevel': 'شدت نیاز',
      'volumeEstimation': 'تقریب حجم',
      'small': 'کم',
      'medium': 'متوسط',
      'large': 'زیاد',
      'notes': 'یادداشت‌ها',
      'save': 'ذخیره',
      'currentStreak': 'رکورد فعلی',
      'longestStreak': 'بهترین رکورد',
      'dry': 'خشک',
      'wet': 'خیس',
      'wokeToPee': 'برای ادرار بیدار شد',
      'fluidRestriction': 'محدودیت مایعات شبانه',
      'logFor': 'ثبت برای',
      'saveNightLog': 'ذخیره ثبت شب',
      'bristolSelector': 'انتخاب مقیاس بریستول',
      'straining': 'شدت فشار',
      'none': 'بدون',
      'moderate': 'متوسط',
      'severe': 'شدید',
      'bloodPresent': 'خون در مدفوع',
      'soilingAccident': 'تصادف مدفوع',
      'logBowel': 'ثبت مدفوع',
      'recentLogs': 'ثبت‌های اخیر',
      'clinicalSummary': 'خلاصه اطلاعات بالینی',
      'generatePdf': 'ایجاد و اشتراک‌گذاری PDF',
      'exportCsv': 'خروجی CSV',
      'noLogsYet': 'هنوز ثبتی وجود ندارد',
    },
    'en': {
      'appTitle': 'Behravan Pediatric Tracker',
      'voidingTab': 'Voiding',
      'enuresisTab': 'Enuresis',
      'bowelTab': 'Bowel',
      'reportsTab': 'Reports',
      'voidingSchedule': 'Timed Voiding Schedule',
      'quickVoidingLogger': 'Quick Voiding Logger',
      'eventType': 'Event Type',
      'promptedSuccess': 'Success (Prompted)',
      'spontaneous': 'Spontaneous',
      'accident': 'Accident',
      'urgencyLevel': 'Urgency Level',
      'volumeEstimation': 'Volume Estimation',
      'small': 'Small',
      'medium': 'Medium',
      'large': 'Large',
      'notes': 'Notes',
      'save': 'Save',
      'currentStreak': 'Current Streak',
      'longestStreak': 'Longest Streak',
      'dry': 'Dry',
      'wet': 'Wet',
      'wokeToPee': 'Woke up to void',
      'fluidRestriction': 'Evening fluid restriction',
      'logFor': 'Log for',
      'saveNightLog': 'Save Night Log',
      'bristolSelector': 'Bristol Stool Scale Selector',
      'straining': 'Straining Intensity',
      'none': 'None',
      'moderate': 'Moderate',
      'severe': 'Severe',
      'bloodPresent': 'Blood present in stool',
      'soilingAccident': 'Soiling / Encopresis accident',
      'logBowel': 'Log Bowel Movement',
      'recentLogs': 'Recent Logs',
      'clinicalSummary': 'Clinical Data Summary',
      'generatePdf': 'Generate & Share PDF Report',
      'exportCsv': 'Export CSV',
      'noLogsYet': 'No logs recorded yet',
    },
  };

  String translate(String key) {
    return _translations[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fa', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
