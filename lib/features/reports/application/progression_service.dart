import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../domain/progression_models.dart';

final progressionEvaluationProvider = Provider<IntervalEvaluationResult?>((
  ref,
) {
  final logsAsync = ref.watch(voidingLogsProvider);
  final schedulesAsync = ref.watch(voidingSchedulesProvider);

  if (logsAsync.value == null ||
      schedulesAsync.value == null ||
      schedulesAsync.value!.isEmpty) {
    return null;
  }

  final logs = logsAsync.value!;
  final activeSchedule = schedulesAsync.value!.first;
  final now = DateTime.now();
  final prefs = ref.watch(sharedPreferencesProvider);
  final lastChangeStr = prefs.getString('last_interval_change');
  final threeDaysAgo = now.subtract(const Duration(days: 3));

  if (lastChangeStr != null) {
    final lastChange = DateTime.parse(lastChangeStr);
    final daysSinceChange = now.difference(lastChange).inDays;

    if (daysSinceChange < 3) {
      return IntervalEvaluationResult(
        totalLogs: 0, // Bypass stats display during cooldown
        successfulLogs: 0,
        accidentLogs: 0,
        spontaneousLogs: 0,
        successRate: 0.0,
        status: ProgressionStatus.maintain, // Force maintain
        currentInterval: activeSchedule.intervalMinutes,
        suggestedInterval: activeSchedule.intervalMinutes,
        recommendationMessage:
            'فاصله زمانی اخیراً تغییر کرده است. در حال ارزیابی برنامه جدید... (${3 - daysSinceChange} روز تا ارزیابی بعدی)',
      );
    }
  }

  // Filter daytime logs in trailing 3-day window
  final windowLogs = logs
      .where((l) => l.timestamp.isAfter(threeDaysAgo))
      .toList();

  int successes = 0;
  int accidents = 0;
  int spontaneous = 0;

  for (final l in windowLogs) {
    if (l.eventType == 'prompted_success') {
      successes++;
    } else if (l.eventType == 'accident') {
      accidents++;
    } else if (l.eventType == 'spontaneous') {
      spontaneous++;
    }
  }

  final total = windowLogs.length;
  final double successRate = total > 0
      ? ((successes + spontaneous) / total)
      : 0.0;
  final currentInterval = activeSchedule.intervalMinutes;

  if (total < 6) {
    return IntervalEvaluationResult(
      totalLogs: total,
      successfulLogs: successes,
      accidentLogs: accidents,
      spontaneousLogs: spontaneous,
      successRate: successRate,
      status: ProgressionStatus.insufficientData,
      currentInterval: currentInterval,
      suggestedInterval: currentInterval,
      recommendationMessage:
          'اطلاعات ۳ روز اخیر کافی نیست (حداقل ۶ ثبت نیاز است). برنامه فعلی را ادامه دهید.',
    );
  }

  if (successRate >= 0.80) {
    final nextInterval = (currentInterval + 15).clamp(45, 180);
    final isAtMax = currentInterval >= 180;

    return IntervalEvaluationResult(
      totalLogs: total,
      successfulLogs: successes,
      accidentLogs: accidents,
      spontaneousLogs: spontaneous,
      successRate: successRate,
      status: ProgressionStatus.progress,
      currentInterval: currentInterval,
      suggestedInterval: nextInterval,
      recommendationMessage: isAtMax
          ? 'عملکرد عالی! کودک در سقف فاصله زمانی (۱۸۰ دقیقه) قرار دارد.'
          : 'عملکرد کودک عالی بوده است (${(successRate * 100).toInt()}% موفقیت). افزایش فاصله توصیه می‌شود.',
    );
  } else if (successRate < 0.50 && accidents >= 3) {
    final prevInterval = (currentInterval - 15).clamp(45, 180);
    return IntervalEvaluationResult(
      totalLogs: total,
      successfulLogs: successes,
      accidentLogs: accidents,
      spontaneousLogs: spontaneous,
      successRate: successRate,
      status: ProgressionStatus.regress,
      currentInterval: currentInterval,
      suggestedInterval: prevInterval,
      recommendationMessage:
          'تعداد تصادف‌ها در ۳ روز گذشته بالا بوده است. کاهش موقت فاصله برای بازیابی کنترل توصیه می‌شود.',
    );
  } else {
    return IntervalEvaluationResult(
      totalLogs: total,
      successfulLogs: successes,
      accidentLogs: accidents,
      spontaneousLogs: spontaneous,
      successRate: successRate,
      status: ProgressionStatus.maintain,
      currentInterval: currentInterval,
      suggestedInterval: currentInterval,
      recommendationMessage:
          'روند درمانی پایدار است (${(successRate * 100).toInt()}% موفقیت). همین فاصله را ادامه دهید.',
    );
  }
});
