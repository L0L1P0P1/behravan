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

  /// 24-hour clock text for a timestamp (e.g., 08:05)
  static String clock(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  /// 'امروز', 'دیروز', or a short Shamsi date such as '۱۲ آبان'
  static String relativeDay(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final isSameDay =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    if (isSameDay) return 'امروز';

    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
    if (isYesterday) return 'دیروز';

    final jalali = Jalali.fromDateTime(date);
    return '${jalali.day} ${jalali.formatter.mN}';
  }
}
