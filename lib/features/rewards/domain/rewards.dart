import 'package:intl/intl.dart';

import '../../../data/database/app_database.dart';
import '../../enuresis/domain/dry_streaks.dart';

/// A growth stage of the child's garden. Plants need both sun and rain, which
/// is the point: every honest entry, wet nights included, helps it grow.
class RewardLevel {
  final int number;
  final String emoji;
  final String title;
  final int minStars;

  const RewardLevel(this.number, this.emoji, this.title, this.minStars);
}

const rewardLevels = [
  RewardLevel(1, '🌱', 'جوانه کوچک', 0),
  RewardLevel(2, '🌿', 'نهال', 25),
  RewardLevel(3, '🌷', 'غنچه', 75),
  RewardLevel(4, '🌻', 'آفتابگردان', 150),
  RewardLevel(5, '🌳', 'درخت تنومند', 300),
  RewardLevel(6, '🌈', 'رنگین‌کمان', 500),
  RewardLevel(7, '👑', 'قهرمان باغ', 800),
];

class RewardBadge {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int progress;
  final int target;

  const RewardBadge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
  });

  bool get isUnlocked => progress >= target;
  double get ratio => (progress / target).clamp(0.0, 1.0);
  int get remaining => (target - progress).clamp(0, target);
}

class RewardsSummary {
  final int stars;
  final RewardLevel level;
  final RewardLevel? nextLevel;
  final List<RewardBadge> badges;
  final int loggingStreak;

  const RewardsSummary({
    required this.stars,
    required this.level,
    required this.nextLevel,
    required this.badges,
    required this.loggingStreak,
  });

  /// Share of the way from the current level to the next one.
  double get levelProgress {
    final next = nextLevel;
    if (next == null) return 1;
    return (stars - level.minStars) / (next.minStars - level.minStars);
  }

  List<RewardBadge> get unlocked => [
    for (final b in badges)
      if (b.isUnlocked) b,
  ];

  /// The locked badge closest to being earned, to show as the next goal.
  RewardBadge? get nextGoal {
    final locked = [
      for (final b in badges)
        if (!b.isUnlocked) b,
    ];
    if (locked.isEmpty) return null;
    locked.sort((a, b) => b.ratio.compareTo(a.ratio));
    return locked.first;
  }
}

/// Stars for a single voiding entry. An accident still earns one: logging it
/// honestly is what makes the diary useful to the doctor.
int voidingStars(String eventType) => eventType == 'prompted_success' ? 2 : 1;

int nightStars(bool isDry) => isDry ? 3 : 1;

/// Bristol types 3 to 5 are the healthy range and earn a bonus star.
int bowelStars(int bristolType) => bristolType >= 3 && bristolType <= 5 ? 2 : 1;

RewardsSummary computeRewards({
  required List<VoidingLogEntity> voiding,
  required List<EnuresisLogEntity> nights,
  required List<BowelLogEntity> bowel,
  required DateTime today,
}) {
  final stars =
      voiding.fold<int>(0, (sum, l) => sum + voidingStars(l.eventType)) +
      nights.fold<int>(0, (sum, l) => sum + nightStars(l.isDry)) +
      bowel.fold<int>(0, (sum, l) => sum + bowelStars(l.bristolType));

  final level = rewardLevels.lastWhere((l) => stars >= l.minStars);
  final nextLevel = level.number < rewardLevels.length
      ? rewardLevels[level.number]
      : null;

  final dateKey = DateFormat('yyyy-MM-dd');
  final loggedDays = {
    for (final l in voiding) dateKey.format(l.timestamp),
    for (final l in bowel) dateKey.format(l.timestamp),
    for (final l in nights) l.date,
  };
  final logging = consecutiveDayRuns(loggedDays, today);
  final dryLongest = computeDryStreaks(nights, today).longest;

  final onTime = voiding.where((l) => l.eventType == 'prompted_success').length;
  final healthyBowel = bowel
      .where((l) => l.bristolType >= 3 && l.bristolType <= 5)
      .length;
  final honest =
      voiding.any((l) => l.eventType == 'accident') ||
      nights.any((l) => !l.isDry);

  // A day counts as dry when it has at least four voids and no accident.
  final voidsByDay = <String, List<VoidingLogEntity>>{};
  for (final l in voiding) {
    voidsByDay.putIfAbsent(dateKey.format(l.timestamp), () => []).add(l);
  }
  final dryDays = voidsByDay.values
      .where(
        (day) => day.length >= 4 && day.every((l) => l.eventType != 'accident'),
      )
      .length;

  final totalLogs = voiding.length + nights.length + bowel.length;

  return RewardsSummary(
    stars: stars,
    level: level,
    nextLevel: nextLevel,
    loggingStreak: logging.current,
    badges: [
      RewardBadge(
        id: 'first_log',
        emoji: '✏️',
        title: 'اولین قدم',
        description: 'اولین ثبت در دفترچه',
        progress: totalLogs.clamp(0, 1),
        target: 1,
      ),
      RewardBadge(
        id: 'honest',
        emoji: '🦁',
        title: 'شجاع و راستگو',
        description: 'ثبت صادقانه یک شب بارانی یا خیس شدن',
        progress: honest ? 1 : 0,
        target: 1,
      ),
      for (final (id, emoji, title, target) in const [
        ('dry_3', '🌤️', '۳ شب آفتابی', 3),
        ('dry_7', '☀️', 'یک هفته آفتابی', 7),
        ('dry_14', '🌞', 'دو هفته آفتابی', 14),
        ('dry_30', '🏆', 'یک ماه آفتابی', 30),
      ])
        RewardBadge(
          id: id,
          emoji: emoji,
          title: title,
          description: '$target شب خشک پشت سر هم',
          progress: dryLongest,
          target: target,
        ),
      for (final (id, emoji, title, target) in const [
        ('diary_3', '📒', 'دفترچه‌نویس', 3),
        ('diary_7', '📚', 'دفترچه‌نویس منظم', 7),
        ('diary_30', '🎖️', 'استاد دفترچه', 30),
      ])
        RewardBadge(
          id: id,
          emoji: emoji,
          title: title,
          description: '$target روز ثبت پشت سر هم',
          progress: logging.longest,
          target: target,
        ),
      RewardBadge(
        id: 'on_time_10',
        emoji: '⏰',
        title: 'سر وقت',
        description: '۱۰ بار دستشویی رفتن با یادآوری',
        progress: onTime,
        target: 10,
      ),
      RewardBadge(
        id: 'dry_day',
        emoji: '💧',
        title: 'روز بی‌خیسی',
        description: 'یک روز با حداقل ۴ بار ادرار و بدون خیس شدن',
        progress: dryDays.clamp(0, 1),
        target: 1,
      ),
      RewardBadge(
        id: 'voids_50',
        emoji: '🚀',
        title: 'پنجاه‌تایی',
        description: '۵۰ بار ثبت ادرار',
        progress: voiding.length,
        target: 50,
      ),
      RewardBadge(
        id: 'happy_tummy',
        emoji: '🍎',
        title: 'شکم شاد',
        description: '۵ بار مدفوع سالم (نوع ۳ تا ۵ بریستول)',
        progress: healthyBowel,
        target: 5,
      ),
    ],
  );
}

/// Current and longest runs of consecutive calendar days among [dayKeys]
/// ('yyyy-MM-dd'). Like the dry streak, a missing today doesn't end the
/// current run.
({int current, int longest}) consecutiveDayRuns(
  Set<String> dayKeys,
  DateTime today,
) {
  final dateKey = DateFormat('yyyy-MM-dd');
  String keyDaysAgo(int days) =>
      dateKey.format(DateTime(today.year, today.month, today.day - days));

  var current = 0;
  for (
    var i = dayKeys.contains(keyDaysAgo(0)) ? 0 : 1;
    dayKeys.contains(keyDaysAgo(i));
    i++
  ) {
    current++;
  }

  // UTC keeps every day exactly 24 hours long across DST changes.
  final sorted = dayKeys.map((d) => DateTime.parse('${d}T00:00:00Z')).toList()
    ..sort();
  var longest = 0;
  var run = 0;
  DateTime? previous;
  for (final day in sorted) {
    run = previous != null && day.difference(previous).inDays == 1
        ? run + 1
        : 1;
    if (run > longest) longest = run;
    previous = day;
  }

  return (current: current, longest: longest);
}
