import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';
import 'widgets/jalali_calendar_grid.dart';

class EnuresisScreen extends ConsumerStatefulWidget {
  const EnuresisScreen({super.key});

  @override
  ConsumerState<EnuresisScreen> createState() => _EnuresisScreenState();
}

class _EnuresisScreenState extends ConsumerState<EnuresisScreen> {
  final _uuid = const Uuid();
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  String _formatJalaliFriendly(DateTime date) {
    final j = Jalali.fromDateTime(date);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;

    final prefix = isToday ? 'امروز (' : (isYesterday ? 'دیروز (' : '');
    final suffix = (isToday || isYesterday) ? ')' : '';
    return '$prefix${j.formatter.wN}، ${j.day} ${j.formatter.mN} ${j.year}$suffix';
  }

  Future<void> _saveNightStatus({
    required bool isDry,
    bool wokeToPee = false,
    bool fluidRestriction = false,
    String? notes,
  }) async {
    HapticFeedback.mediumImpact();
    final db = ref.read(databaseProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);

    final existing = await (db.select(
      db.enuresisLogs,
    )..where((t) => t.date.equals(dateStr))).getSingleOrNull();

    if (existing != null) {
      await (db.update(
        db.enuresisLogs,
      )..where((t) => t.id.equals(existing.id))).write(
        EnuresisLogsCompanion(
          isDry: Value(isDry),
          wokeToPee: Value(wokeToPee),
          eveningFluidRestriction: Value(fluidRestriction),
          notes: Value(notes),
        ),
      );
    } else {
      await db
          .into(db.enuresisLogs)
          .insert(
            EnuresisLogsCompanion.insert(
              id: _uuid.v4(),
              date: dateStr,
              isDry: isDry,
              wokeToPee: Value(wokeToPee),
              eveningFluidRestriction: Value(fluidRestriction),
              notes: Value(notes),
            ),
          );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: const Duration(milliseconds: 2200),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isDry ? Icons.star_rounded : Icons.nights_stay_rounded,
                color: isDry
                    ? const Color(0xFF059669)
                    : const Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isDry
                      ? 'ثبت شد؛ آفرین به قهرمان ما! 🌟'
                      : 'وضعیت بامداد ثبت شد؛ نگران نباش، ادامه می‌دیم! 🌙',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNightDetailSheet({
    required bool isDry,
    required EnuresisLogEntity? existingLog,
  }) {
    bool wokeToPee = existingLog?.wokeToPee ?? false;
    bool fluidRestriction = existingLog?.eveningFluidRestriction ?? false;
    final notesCtrl = TextEditingController(text: existingLog?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              (isDry
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDry
                              ? Icons.wb_sunny_rounded
                              : Icons.nightlight_round,
                          color: isDry
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDry
                                ? 'جزئیات شب خشک (موفق)'
                                : 'جزئیات شب خیس (تصادف)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            _formatJalaliFriendly(_selectedDay),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'محدودیت مصرف مایعات عصر/شب رعایت شد؟',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'عدم مصرف نوشیدنی‌های شیرین و کافئین‌دار قبل خواب',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: fluidRestriction,
                    activeThumbColor: const Color(0xFF0284C7),
                    activeTrackColor: const Color(0xFFBAE6FD),
                    onChanged: (v) => setSheetState(() => fluidRestriction = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'در طول شب برای دستشویی بیدار شد؟',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'بیدار شدن خودبه‌خودی یا با کمک والدین جهت تخلیه مثانه',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: wokeToPee,
                    activeThumbColor: const Color(0xFF0284C7),
                    activeTrackColor: const Color(0xFFBAE6FD),
                    onChanged: (v) => setSheetState(() => wokeToPee = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      hintText:
                          'توضیحات اختیاری (بیماری، مصرف داروها، خواب سنگین)...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDry
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveNightStatus(
                          isDry: isDry,
                          wokeToPee: wokeToPee,
                          fluidRestriction: fluidRestriction,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );
                      },
                      child: Text(
                        isDry ? 'ثبت نهایی شب خشک' : 'ثبت نهایی شب خیس',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final enuresisAsync = ref.watch(enuresisLogsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'پیگیری شب‌ادراری (Enuresis)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: enuresisAsync.when(
        data: (logs) {
          final Map<String, EnuresisLogEntity> logMap = {
            for (var l in logs) l.date: l,
          };

          // Robust Streak Engine: Does not reset if today's morning log is still pending
          int currentStreak = 0;
          int longestStreak = 0;
          int runningTemp = 0;

          final now = DateTime.now();
          final todayMidnight = DateTime(now.year, now.month, now.day);
          final todayKey = DateFormat('yyyy-MM-dd').format(todayMidnight);
          final hasTodayLog = logMap.containsKey(todayKey);

          final startIndex = hasTodayLog ? 0 : 1;

          for (int i = startIndex; i < 90; i++) {
            final day = todayMidnight.subtract(Duration(days: i));
            final key = DateFormat('yyyy-MM-dd').format(day);
            final log = logMap[key];

            if (log != null && log.isDry) {
              currentStreak++;
            } else {
              break;
            }
          }

          // Longest streak calculation over full log history
          for (int i = 0; i < 90; i++) {
            final day = todayMidnight.subtract(Duration(days: i));
            final key = DateFormat('yyyy-MM-dd').format(day);
            final log = logMap[key];

            if (log != null && log.isDry) {
              runningTemp++;
              if (runningTemp > longestStreak) longestStreak = runningTemp;
            } else {
              runningTemp = 0;
            }
          }

          final selectedDateKey = DateFormat('yyyy-MM-dd').format(_selectedDay);
          final selectedLog = logMap[selectedDateKey];
          final isFuture = _selectedDay.isAfter(todayMidnight);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // 1. Dashboard Metrics Card
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFF059669),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'پیوستگی خشک فعلی',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currentStreak شب',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                color: Color(0xFF0284C7),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'بهترین رکورد',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$longestStreak شب',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Interactive Day Inspector & Action Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatJalaliFriendly(_selectedDay),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        if (selectedLog != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (selectedLog.isDry
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B))
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedLog.isDry
                                  ? 'ثبت شده: خشک'
                                  : 'ثبت شده: خیس',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selectedLog.isDry
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (selectedLog != null) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (selectedLog.eveningFluidRestriction)
                            const _FeatureChip(
                              label: 'محدودیت مایعات رعایت شد',
                              icon: Icons.no_drinks_rounded,
                              color: Color(0xFF0284C7),
                            ),
                          if (selectedLog.wokeToPee)
                            const _FeatureChip(
                              label: 'بیداری جهت تخلیه شبانه',
                              icon: Icons.alarm_on_rounded,
                              color: Color(0xFF8B5CF6),
                            ),
                          if (selectedLog.notes != null &&
                              selectedLog.notes!.isNotEmpty)
                            _FeatureChip(
                              label: selectedLog.notes!,
                              icon: Icons.note_outlined,
                              color: const Color(0xFF64748B),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),

                    if (isFuture)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'امکان ثبت وضعیت برای تاریخ آینده وجود ندارد.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _saveNightStatus(isDry: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedLog?.isDry == true
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selectedLog?.isDry == true
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF86EFAC),
                                    width: selectedLog?.isDry == true ? 2 : 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wb_sunny_rounded,
                                      color: Color(0xFF059669),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'شب خشک',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF065F46),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showNightDetailSheet(
                                isDry: false,
                                existingLog: selectedLog,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      selectedLog != null && !selectedLog.isDry
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        selectedLog != null &&
                                            !selectedLog.isDry
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFFFDE68A),
                                    width:
                                        selectedLog != null &&
                                            !selectedLog.isDry
                                        ? 2
                                        : 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.nightlight_round,
                                      color: Color(0xFFD97706),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'شب خیس',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Calendar Grid Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: JalaliCalendarGrid(
                  selectedDate: Jalali.fromDateTime(_selectedDay),
                  onDaySelected: (newDate) {
                    setState(() => _selectedDay = newDate.toDateTime());
                  },
                  logMap: logMap,
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => Center(child: Text('خطا: $e')),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _FeatureChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
