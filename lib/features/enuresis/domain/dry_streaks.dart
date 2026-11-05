import 'package:intl/intl.dart';

import '../../../data/database/app_database.dart';

/// Current and best runs of consecutive dry nights across the whole history.
/// A missing log for today doesn't break the current run, because the morning
/// entry may simply not have been made yet.
({int current, int longest}) computeDryStreaks(
  Iterable<EnuresisLogEntity> logs,
  DateTime today,
) {
  final dryDates = {
    for (final log in logs)
      if (log.isDry) log.date,
  };
  final loggedDates = {for (final log in logs) log.date};

  final dateKey = DateFormat('yyyy-MM-dd');
  String keyDaysAgo(int days) =>
      dateKey.format(DateTime(today.year, today.month, today.day - days));

  var current = 0;
  for (
    var i = loggedDates.contains(keyDaysAgo(0)) ? 0 : 1;
    dryDates.contains(keyDaysAgo(i));
    i++
  ) {
    current++;
  }

  // UTC keeps every day exactly 24 hours long across DST changes.
  final sortedDays =
      dryDates.map((d) => DateTime.parse('${d}T00:00:00Z')).toList()..sort();

  var longest = 0;
  var run = 0;
  DateTime? previous;
  for (final day in sortedDays) {
    run = previous != null && day.difference(previous).inDays == 1
        ? run + 1
        : 1;
    if (run > longest) longest = run;
    previous = day;
  }

  return (current: current, longest: longest);
}
