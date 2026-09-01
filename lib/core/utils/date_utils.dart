import 'package:shamsi_date/shamsi_date.dart';

class PersianDateFormatter {
  /// Converts a standard DateTime to a readable Shamsi string (e.g., ۱۴۰۲/۰۶/۱۰)
  static String toPersianDateStr(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    final y = jalali.year;
    final m = jalali.month.toString().padLeft(2, '0');
    final d = jalali.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  /// Parses your DB 'yyyy-MM-dd' string and formats it to Shamsi
  static String formatDbDateToPersian(String dbDate) {
    final parsed = DateTime.tryParse(dbDate);
    if (parsed == null) return dbDate;
    return toPersianDateStr(parsed);
  }
}
