import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/database/app_database.dart';
import '../domain/dry_streaks.dart';
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
    AppToast.show(
      context,
      message: isDry
          ? 'ثبت شد؛ آفرین به قهرمان ما! 🌟'
          : 'ثبت شد؛ نگران نباش، ادامه می‌دیم! 🌙',
      tone: isDry ? ToastTone.success : ToastTone.gentle,
    );
  }

  Future<void> _deleteNightLog(EnuresisLogEntity log) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.enuresisLogs)..where((t) => t.id.equals(log.id))).go();

    if (!mounted) return;
    HapticFeedback.lightImpact();
    AppToast.show(
      context,
      message: 'ثبت این شب حذف شد.',
      tone: ToastTone.neutral,
      onUndo: () => db.into(db.enuresisLogs).insert(log),
    );
  }

  void _showNightDetailSheet({
    required bool isDry,
    required EnuresisLogEntity? existingLog,
  }) {
    bool wokeToPee = existingLog?.wokeToPee ?? false;
    bool fluidRestriction = existingLog?.eveningFluidRestriction ?? false;
    final notesCtrl = TextEditingController(text: existingLog?.notes ?? '');

    showAppSheet(
      context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return AppSheetBody(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDry
                            ? AppColors.successSoft
                            : AppColors.gentleSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDry ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        color: isDry ? AppColors.success : AppColors.gentle,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDry ? 'جزئیات شب خشک' : 'جزئیات شب خیس',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            _formatJalaliFriendly(_selectedDay),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'محدودیت مایعات عصر و شب رعایت شد؟',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'بدون نوشیدنی شیرین یا کافئین‌دار قبل از خواب',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  value: fluidRestriction,
                  onChanged: (v) => setSheetState(() => fluidRestriction = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'شب برای دستشویی بیدار شد؟',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'خودش بیدار شد یا با کمک والدین',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  value: wokeToPee,
                  onChanged: (v) => setSheetState(() => wokeToPee = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    hintText: 'یادداشت اختیاری (بیماری، دارو، خواب سنگین)...',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDry
                          ? AppColors.success
                          : AppColors.gentle,
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
                    child: Text(isDry ? 'ثبت شب خشک' : 'ثبت شب خیس'),
                  ),
                ),
                if (existingLog != null)
                  SheetDeleteButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteNightLog(existingLog);
                    },
                  ),
              ],
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
      appBar: AppBar(title: const Text('پیگیری شب‌ادراری')),
      body: enuresisAsync.when(
        data: (logs) {
          final Map<String, EnuresisLogEntity> logMap = {
            for (var l in logs) l.date: l,
          };

          final now = DateTime.now();
          final todayMidnight = DateTime(now.year, now.month, now.day);
          final streaks = computeDryStreaks(logs, todayMidnight);

          final selectedDateKey = DateFormat('yyyy-MM-dd').format(_selectedDay);
          final selectedLog = logMap[selectedDateKey];
          final isDryNight = selectedLog?.isDry == true;
          final isWetNight = selectedLog?.isDry == false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            children: [
              // 1. Dashboard Metrics Card
              Row(
                children: [
                  Expanded(
                    child: _StreakCard(
                      title: 'پیوستگی شب‌های خشک',
                      nights: streaks.current,
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.success,
                      valueColor: AppColors.successDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StreakCard(
                      title: 'بهترین رکورد',
                      nights: streaks.longest,
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppColors.primary,
                      valueColor: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Interactive Day Inspector & Action Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatJalaliFriendly(_selectedDay),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (selectedLog == null)
                      Text(
                        _selectedDay == todayMidnight
                            ? 'دیشب چطور گذشت؟'
                            : 'این شب چطور گذشت؟',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      )
                    else if (selectedLog.eveningFluidRestriction ||
                        selectedLog.wokeToPee ||
                        (selectedLog.notes?.isNotEmpty ?? false))
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (selectedLog.eveningFluidRestriction)
                            const _FeatureChip(
                              label: 'محدودیت مایعات رعایت شد',
                              icon: Icons.no_drinks_rounded,
                              color: AppColors.primaryDark,
                            ),
                          if (selectedLog.wokeToPee)
                            const _FeatureChip(
                              label: 'بیدار شدن برای دستشویی',
                              icon: Icons.alarm_on_rounded,
                              color: Color(0xFF7C3AED),
                            ),
                          if (selectedLog.notes?.isNotEmpty ?? false)
                            _FeatureChip(
                              label: selectedLog.notes!,
                              icon: Icons.note_outlined,
                              color: AppColors.muted,
                            ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _NightChoiceButton(
                            label: 'شب خشک',
                            icon: Icons.wb_sunny_rounded,
                            isSelected: isDryNight,
                            accent: AppColors.success,
                            textColor: AppColors.successDark,
                            selectedFill: AppColors.successSoft,
                            idleFill: const Color(0xFFF0FDF4),
                            idleBorder: const Color(0xFF86EFAC),
                            // Keeps any details already saved for this night.
                            onTap: () => _saveNightStatus(
                              isDry: true,
                              wokeToPee: selectedLog?.wokeToPee ?? false,
                              fluidRestriction:
                                  selectedLog?.eveningFluidRestriction ?? false,
                              notes: selectedLog?.notes,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NightChoiceButton(
                            label: 'شب خیس',
                            icon: Icons.nightlight_round,
                            isSelected: isWetNight,
                            accent: AppColors.gentle,
                            textColor: AppColors.gentleDark,
                            selectedFill: AppColors.gentleSoft,
                            idleFill: const Color(0xFFFFFBEB),
                            idleBorder: const Color(0xFFFDE68A),
                            onTap: () => _showNightDetailSheet(
                              isDry: false,
                              existingLog: selectedLog,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedLog != null) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.muted,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text(
                            'جزئیات و ویرایش',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => _showNightDetailSheet(
                            isDry: selectedLog.isDry,
                            existingLog: selectedLog,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Calendar Grid Card
              AppCard(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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

class _StreakCard extends StatelessWidget {
  final String title;
  final int nights;
  final IconData icon;
  final Color iconColor;
  final Color valueColor;

  const _StreakCard({
    required this.title,
    required this.nights,
    required this.icon,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$nights شب',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _NightChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accent;
  final Color textColor;
  final Color selectedFill;
  final Color idleFill;
  final Color idleBorder;
  final VoidCallback onTap;

  const _NightChoiceButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accent,
    required this.textColor,
    required this.selectedFill,
    required this.idleFill,
    required this.idleBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? selectedFill : idleFill,
        border: Border.all(
          color: isSelected ? accent : idleBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? Icons.check_circle_rounded : icon,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
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
                fontSize: 12,
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
