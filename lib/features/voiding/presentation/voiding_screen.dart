import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/database/app_database.dart';
import '../../reports/application/progression_service.dart';
import '../../reports/domain/progression_models.dart';
import '../../reports/presentation/widgets/celebration_dialog.dart';

/// Whether the child is close enough to the next slot to be asked to hold on.
bool _isInHoldingWindow({
  required DateTime now,
  required DateTime? targetTime,
  required int intervalMinutes,
}) {
  if (targetTime == null) return false;
  final remaining = targetTime.difference(now);

  if (remaining.isNegative || remaining.inSeconds <= 0) return false;

  final intervalSecs = intervalMinutes * 60;
  if (intervalSecs <= 0) return false;

  final remainingSecs = remaining.inSeconds;
  if (intervalSecs <= 120) {
    return remainingSecs <= 25 || (remainingSecs / intervalSecs) <= 0.35;
  }

  final ratio = remainingSecs / intervalSecs;
  return ratio <= 0.15 || remainingSecs <= 600;
}

// -----------------------------------------------------------------------------
// Main Screen
// -----------------------------------------------------------------------------
class VoidingScreen extends ConsumerStatefulWidget {
  const VoidingScreen({super.key});

  @override
  ConsumerState<VoidingScreen> createState() => _VoidingScreenState();
}

class _VoidingScreenState extends ConsumerState<VoidingScreen> {
  final _uuid = const Uuid();
  DateTime? _lastManualResetTime;
  Timer? _minuteTicker;

  @override
  void initState() {
    super.initState();
    // Picks up the moment the active window opens or closes.
    _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minuteTicker?.cancel();
    super.dispose();
  }

  DateTime? _calculateTargetTime(
    VoidingScheduleEntity? schedule,
    List<VoidingLogEntity> logs,
  ) {
    if (schedule == null || !schedule.isActive) return null;

    final now = DateTime.now();
    final interval = Duration(minutes: schedule.intervalMinutes);
    final windowStart = _todayAt(now, schedule.startTime);
    final windowEnd = _todayAt(now, schedule.endTime);

    // Mirrors NotificationService: short test intervals ignore the window.
    final isOutsideWindow =
        schedule.intervalMinutes > 30 &&
        (now.isBefore(windowStart) || !now.isBefore(windowEnd));
    if (isOutsideWindow) return null;

    VoidingLogEntity? latestLog;
    if (logs.isNotEmpty) {
      latestLog = logs.reduce(
        (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
      );
    }

    DateTime? effectiveLastTime = latestLog?.timestamp;
    if (_lastManualResetTime != null) {
      if (effectiveLastTime == null ||
          _lastManualResetTime!.isAfter(effectiveLastTime)) {
        effectiveLastTime = _lastManualResetTime;
      }
    }

    // Yesterday's last log must not read as "12 hours overdue" this morning.
    if (effectiveLastTime != null && effectiveLastTime.isAfter(windowStart)) {
      return effectiveLastTime.add(interval);
    }

    final nextAlarm = NotificationService.instance.currentNextAlarm;
    if (nextAlarm != null && nextAlarm.isAfter(now)) {
      return nextAlarm;
    }

    return now.add(interval);
  }

  DateTime _todayAt(DateTime now, String hhmm) {
    final parts = hhmm.split(':').map(int.parse).toList();
    return DateTime(now.year, now.month, now.day, parts[0], parts[1]);
  }

  String _resolveEventType({
    required DateTime now,
    required DateTime? targetTime,
    required int intervalMinutes,
    required bool isActive,
  }) {
    if (!isActive || targetTime == null) {
      return 'spontaneous';
    }

    final intervalSecs = intervalMinutes * 60;
    final preGraceSecs = intervalSecs <= 120
        ? 20
        : (intervalSecs * 0.1).clamp(15, 120).toInt();
    final postGraceSecs = intervalSecs < 900 ? intervalSecs : 900;

    final diffSeconds = now.difference(targetTime).inSeconds;
    final isWithinPromptWindow =
        diffSeconds >= -preGraceSecs && diffSeconds <= postGraceSecs;

    return isWithinPromptWindow ? 'prompted_success' : 'spontaneous';
  }

  Future<void> _undoLog(String logId) async {
    setState(() {
      _lastManualResetTime = null;
    });

    final db = ref.read(databaseProvider);
    await (db.delete(db.voidingLogs)..where((t) => t.id.equals(logId))).go();
    await NotificationService.instance.resetTimerForActiveSchedules(db);

    if (!mounted) return;
    HapticFeedback.lightImpact();

    AppToast.show(
      context,
      message: 'ثبت قبلی لغو شد.',
      tone: ToastTone.neutral,
      duration: const Duration(milliseconds: 1600),
    );
  }

  Future<void> _saveVoidingLog({
    required String eventType,
    DateTime? timestamp,
    int urgency = 1,
    String volume = 'medium',
    String? notes,
  }) async {
    HapticFeedback.mediumImpact();
    final db = ref.read(databaseProvider);
    final logTime = timestamp ?? DateTime.now();
    final newId = _uuid.v4();

    setState(() {
      _lastManualResetTime = logTime;
    });

    final log = VoidingLogsCompanion.insert(
      id: newId,
      timestamp: logTime,
      eventType: eventType,
      urgencyLevel: Value(urgency),
      volumeEstimation: Value(volume),
      notes: Value(notes),
    );

    await db.into(db.voidingLogs).insert(log);
    await NotificationService.instance.resetTimerForActiveSchedules(db);

    if (!mounted) return;

    final isAccident = eventType == 'accident';
    final isPrompted = eventType == 'prompted_success';

    AppToast.show(
      context,
      message: isAccident
          ? 'ثبت شد؛ قدم به قدم بهتر می‌شیم!'
          : (isPrompted
                ? 'آفرین! ثبت به‌موقع با یادآور ساعت ⏰'
                : 'رویداد ثبت و تایمر بازنشانی شد.'),
      tone: isAccident ? ToastTone.gentle : ToastTone.success,
      onUndo: () => _undoLog(newId),
    );
  }

  bool _isLatestLog(VoidingLogEntity log) =>
      ref.read(voidingLogsProvider).value?.firstOrNull?.id == log.id;

  /// The timer follows the latest log, so only changes to it re-arm the alarm.
  Future<void> _refreshTimerAfterChange({required bool affectsTimer}) async {
    if (!affectsTimer) return;
    setState(() => _lastManualResetTime = null);
    await NotificationService.instance.resetTimerForActiveSchedules(
      ref.read(databaseProvider),
    );
  }

  Future<void> _updateVoidingLog(
    VoidingLogEntity log, {
    required String eventType,
    required DateTime timestamp,
    required int urgency,
    required String volume,
    String? notes,
  }) async {
    final affectsTimer = _isLatestLog(log) && timestamp != log.timestamp;
    final db = ref.read(databaseProvider);

    await (db.update(db.voidingLogs)..where((t) => t.id.equals(log.id))).write(
      VoidingLogsCompanion(
        timestamp: Value(timestamp),
        eventType: Value(eventType),
        urgencyLevel: Value(urgency),
        volumeEstimation: Value(volume),
        notes: Value(notes),
      ),
    );
    await _refreshTimerAfterChange(affectsTimer: affectsTimer);

    if (!mounted) return;
    AppToast.show(context, message: 'تغییرات ذخیره شد.');
  }

  Future<void> _deleteVoidingLog(VoidingLogEntity log) async {
    final affectsTimer = _isLatestLog(log);
    final db = ref.read(databaseProvider);

    await (db.delete(db.voidingLogs)..where((t) => t.id.equals(log.id))).go();
    await _refreshTimerAfterChange(affectsTimer: affectsTimer);

    if (!mounted) return;
    HapticFeedback.lightImpact();
    AppToast.show(
      context,
      message: 'ثبت حذف شد.',
      tone: ToastTone.neutral,
      onUndo: () async {
        await db.into(db.voidingLogs).insert(log);
        await _refreshTimerAfterChange(affectsTimer: affectsTimer);
      },
    );
  }

  Future<void> _handleQuickSuccessTap({
    required DateTime? targetTime,
    required VoidingScheduleEntity? schedule,
  }) async {
    final now = DateTime.now();
    final isActive = schedule?.isActive ?? false;
    final interval = schedule?.intervalMinutes ?? 60;

    if (isActive &&
        _isInHoldingWindow(
          now: now,
          targetTime: targetTime,
          intervalMinutes: interval,
        )) {
      final remaining = targetTime!.difference(now);
      final totalSeconds = interval * 60;
      final percentLeft = ((remaining.inSeconds / totalSeconds) * 100).round();

      final timeRemainingStr = remaining.inSeconds < 60
          ? '${remaining.inSeconds} ثانیه'
          : '${remaining.inMinutes} دقیقه';

      final bool? proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFF59E0B),
                size: 26,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'کمی بیشتر صبر کن!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            'فقط $percentLeft٪ از زمان مانده (حدود $timeRemainingStr تا موعد بعدی) ⏳\n\n'
            'قهرمان، اگر می‌تونی چند لحظه بیشتر نگه دار تا گنجایش مثانه‌ات بیشتر بشه. آیا حتماً باید الان بری؟',
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF334155),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'صبر می‌کنم 💪',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نه، باید برم'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    final eventType = _resolveEventType(
      now: now,
      targetTime: targetTime,
      intervalMinutes: interval,
      isActive: isActive,
    );

    await _saveVoidingLog(eventType: eventType);
  }

  void _showDetailedLogSheet({
    String defaultType = 'spontaneous',
    VoidingLogEntity? existing,
  }) {
    showAppSheet(
      context,
      builder: (ctx) => _ClinicalLogDetailSheet(
        initialType: existing?.eventType ?? defaultType,
        existing: existing,
        onDelete: existing == null
            ? null
            : () {
                Navigator.pop(ctx);
                _deleteVoidingLog(existing);
              },
        onSave: (type, time, urgency, volume, notes) async {
          Navigator.pop(ctx);
          if (existing != null) {
            await _updateVoidingLog(
              existing,
              eventType: type,
              timestamp: time,
              urgency: urgency,
              volume: volume,
              notes: notes,
            );
            return;
          }
          await _saveVoidingLog(
            eventType: type,
            timestamp: time,
            urgency: urgency,
            volume: volume,
            notes: notes,
          );
        },
      ),
    );
  }

  Future<void> _applyProgression(int oldInterval, int newInterval) async {
    final db = ref.read(databaseProvider);
    final schedules = await db.select(db.voidingSchedules).get();
    if (schedules.isEmpty) return;

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      'last_interval_change',
      DateTime.now().toIso8601String(),
    );

    final schedule = schedules.first;
    await (db.update(db.voidingSchedules)
          ..where((t) => t.id.equals(schedule.id)))
        .write(VoidingSchedulesCompanion(intervalMinutes: Value(newInterval)));

    if (schedule.isActive) {
      await NotificationService.instance.scheduleDailyVoidingSlots(
        scheduleId: schedule.id,
        title: schedule.title,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        intervalMinutes: newInterval,
      );
    }

    if (mounted) {
      await CelebrationDialog.show(
        context,
        oldInterval: oldInterval,
        newInterval: newInterval,
        onDismiss: () {},
      );
    }
  }

  void _showScheduleModal(
    BuildContext context,
    VoidingScheduleEntity schedule,
  ) {
    showAppSheet(
      context,
      builder: (_) => _ScheduleEditorSheet(schedule: schedule),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(voidingLogsProvider);
    final schedulesAsync = ref.watch(voidingSchedulesProvider);
    final progression = ref.watch(progressionEvaluationProvider);

    final currentSchedule = schedulesAsync.value?.firstOrNull;
    final logs = logsAsync.value ?? [];
    final targetTime = _calculateTargetTime(currentSchedule, logs);

    final canProgress =
        progression != null &&
        progression.status == ProgressionStatus.progress &&
        progression.suggestedInterval > progression.currentInterval;

    return Scaffold(
      appBar: AppBar(title: const Text('برنامه تمرین مثانه')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _HeroRadialProgressCard(
            schedule: currentSchedule,
            targetTime: targetTime,
            onToggleActive: (val) async {
              if (currentSchedule == null) return;
              final db = ref.read(databaseProvider);
              await (db.update(db.voidingSchedules)
                    ..where((t) => t.id.equals(currentSchedule.id)))
                  .write(VoidingSchedulesCompanion(isActive: Value(val)));

              if (val) {
                await NotificationService.instance.scheduleDailyVoidingSlots(
                  scheduleId: currentSchedule.id,
                  title: currentSchedule.title,
                  startTime: currentSchedule.startTime,
                  endTime: currentSchedule.endTime,
                  intervalMinutes: currentSchedule.intervalMinutes,
                );
              } else {
                await NotificationService.instance.cancelScheduleAlarms(
                  currentSchedule.id,
                );
              }
            },
            onEditSchedule: currentSchedule != null
                ? () => _showScheduleModal(context, currentSchedule)
                : null,
          ),
          if (canProgress) ...[
            const SizedBox(height: 14),
            _ProgressionBanner(
              currentInterval: progression.currentInterval,
              suggestedInterval: progression.suggestedInterval,
              successRate: progression.successRate,
              onApply: () => _applyProgression(
                progression.currentInterval,
                progression.suggestedInterval,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _QuickActionCenter(
            onQuickSuccessTap: () => _handleQuickSuccessTap(
              targetTime: targetTime,
              schedule: currentSchedule,
            ),
            onQuickAccidentTap: () =>
                _saveVoidingLog(eventType: 'accident', urgency: 3),
            onOpenDetailedEntry: () => _showDetailedLogSheet(),
          ),
          const SizedBox(height: 24),
          logsAsync.when(
            data: (items) => _VoidingDiaryCard(
              logs: items,
              onLogTap: (log) => _showDetailedLogSheet(existing: log),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Center(child: Text('خطا در بارگذاری: $e')),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Component: Self-Contained Radial Timer Card
// -----------------------------------------------------------------------------
class _HeroRadialProgressCard extends StatefulWidget {
  final VoidingScheduleEntity? schedule;
  final DateTime? targetTime;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback? onEditSchedule;

  const _HeroRadialProgressCard({
    required this.schedule,
    required this.targetTime,
    required this.onToggleActive,
    required this.onEditSchedule,
  });

  @override
  State<_HeroRadialProgressCard> createState() =>
      _HeroRadialProgressCardState();
}

class _HeroRadialProgressCardState extends State<_HeroRadialProgressCard> {
  Timer? _localTicker;

  @override
  void initState() {
    super.initState();
    _localTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && (widget.schedule?.isActive ?? false)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _localTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final isActive = schedule?.isActive ?? false;
    final targetTime = widget.targetTime;

    final now = DateTime.now();
    final diff = targetTime?.difference(now) ?? Duration.zero;
    final isAlarmReady = isActive && targetTime != null && diff.isNegative;
    final totalDuration = Duration(minutes: schedule?.intervalMinutes ?? 60);

    double progress = 1.0;
    if (isActive && targetTime != null && !isAlarmReady) {
      final elapsed = totalDuration - diff;
      progress = (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
    } else if (isAlarmReady) {
      progress = 1.0;
    }

    final absSeconds = diff.inSeconds.abs();
    final minutesLeft = (absSeconds ~/ 60).clamp(0, 999);
    final secondsLeft = (absSeconds % 60).clamp(0, 59);

    final isHoldingPrompt =
        schedule != null &&
        _isInHoldingWindow(
          now: now,
          targetTime: targetTime,
          intervalMinutes: schedule.intervalMinutes,
        );
    final isResting = isActive && targetTime == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'یادآور فعال' : 'یادآور غیرفعال',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isActive,
                  onChanged: widget.onToggleActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: isActive && !isResting ? progress : 0,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAlarmReady
                          ? AppColors.success
                          : (isHoldingPrompt
                                ? const Color(0xFFF59E0B)
                                : AppColors.primary),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isActive) ...[
                        const Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 40,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'توقف موقت',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ] else if (isResting) ...[
                        const Icon(
                          Icons.bedtime_rounded,
                          size: 38,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'زمان استراحت',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'شروع از ساعت ${schedule!.startTime}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ] else if (isAlarmReady) ...[
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 38,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'وقت دستشویی!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          '+${minutesLeft.toString().padLeft(2, '0')}:${secondsLeft.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '${minutesLeft.toString().padLeft(2, '0')}:${secondsLeft.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isHoldingPrompt ? 'کمی صبر کن 💪' : 'تا نوبت بعدی',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isHoldingPrompt
                                ? const Color(0xFFD97706)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (schedule != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onEditSchedule,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_calendar_rounded,
                        size: 16,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'هر ${schedule.intervalMinutes} دقیقه • ساعت ${schedule.startTime} تا ${schedule.endTime}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Component: Action Buttons
// -----------------------------------------------------------------------------
// Component: Action Buttons
// -----------------------------------------------------------------------------
class _QuickActionCenter extends StatelessWidget {
  final VoidCallback onQuickSuccessTap;
  final VoidCallback onQuickAccidentTap;
  final VoidCallback onOpenDetailedEntry;

  const _QuickActionCenter({
    required this.onQuickSuccessTap,
    required this.onQuickAccidentTap,
    required this.onOpenDetailedEntry,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TapSurface(
                onTap: onQuickSuccessTap,
                borderRadius: radius,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'دستشویی رفتم',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TapSurface(
                onTap: onQuickAccidentTap,
                borderRadius: radius,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.gentle,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'خیس شدم',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gentleDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: onOpenDetailedEntry,
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
          icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
          label: const Text(
            'ثبت با جزئیات (زمان، حجم، فوریت، یادداشت)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Component: Progression Milestone Banner
// -----------------------------------------------------------------------------
class _ProgressionBanner extends StatelessWidget {
  final int currentInterval;
  final int suggestedInterval;
  final double successRate;
  final VoidCallback onApply;

  const _ProgressionBanner({
    required this.currentInterval,
    required this.suggestedInterval,
    required this.successRate,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'پیشنهاد افزایش فاصله زمانی! 🎯',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14532D),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$currentInterval ➔ $suggestedInterval دقیقه (${(successRate * 100).toInt()}% روزهای موفق)',
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: onApply,
            child: const Text(
              'ارتقا',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Component: Activity Diary Card
// -----------------------------------------------------------------------------
class _VoidingDiaryCard extends StatelessWidget {
  final List<VoidingLogEntity> logs;
  final ValueChanged<VoidingLogEntity> onLogTap;

  const _VoidingDiaryCard({required this.logs, required this.onLogTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayLogs =
        logs
            .where(
              (l) =>
                  l.timestamp.year == now.year &&
                  l.timestamp.month == now.month &&
                  l.timestamp.day == now.day,
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'دفترچه ثبت امروز',
            trailing: todayLogs.isEmpty ? null : '${todayLogs.length} رویداد',
          ),
          if (todayLogs.isEmpty)
            const EmptyState(
              icon: Icons.water_drop_outlined,
              message: 'امروز هنوز چیزی ثبت نشده است.',
            )
          else ...[
            const SizedBox(height: 2),
            const Text(
              'برای ویرایش یا حذف، روی هر مورد بزنید.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            for (final (index, log) in todayLogs.indexed) ...[
              if (index > 0) const Divider(),
              _DiaryRow(log: log, onTap: () => onLogTap(log)),
            ],
          ],
        ],
      ),
    );
  }
}

class _DiaryRow extends StatelessWidget {
  final VoidingLogEntity log;
  final VoidCallback onTap;

  const _DiaryRow({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAccident = log.eventType == 'accident';
    final isSuccess = log.eventType == 'prompted_success';

    final color = isAccident
        ? AppColors.gentle
        : (isSuccess ? AppColors.success : AppColors.primary);
    final title = isSuccess
        ? 'با یادآور'
        : (isAccident ? 'خیس شدن' : 'خودبه‌خودی');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                log.notes ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              PersianDateFormatter.clock(log.timestamp),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Component: Full Clinical Detail Entry BottomSheet
// -----------------------------------------------------------------------------
class _ClinicalLogDetailSheet extends StatefulWidget {
  final String initialType;
  final VoidingLogEntity? existing;
  final VoidCallback? onDelete;
  final Function(
    String type,
    DateTime time,
    int urgency,
    String volume,
    String? notes,
  )
  onSave;

  const _ClinicalLogDetailSheet({
    required this.initialType,
    required this.onSave,
    this.existing,
    this.onDelete,
  });

  @override
  State<_ClinicalLogDetailSheet> createState() =>
      _ClinicalLogDetailSheetState();
}

class _ClinicalLogDetailSheetState extends State<_ClinicalLogDetailSheet> {
  late String _type;
  int _urgency = 1;
  String _volume = 'medium';
  TimeOfDay _time = TimeOfDay.now();
  final _notesCtrl = TextEditingController();

  // Logs can hold types with no segment here (e.g. 'missed'), so the editor
  // falls back to a default instead of tripping SegmentedButton's assert.
  static const _editableTypes = {'spontaneous', 'prompted_success', 'accident'};

  @override
  void initState() {
    super.initState();
    _type = _editableTypes.contains(widget.initialType)
        ? widget.initialType
        : 'spontaneous';

    final existing = widget.existing;
    if (existing != null) {
      _urgency = existing.urgencyLevel ?? 1;
      _volume = existing.volumeEstimation ?? 'medium';
      _time = TimeOfDay.fromDateTime(existing.timestamp);
      _notesCtrl.text = existing.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.inkSoft,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AppSheetBody(
      children: [
        Text(
          isEditing ? 'ویرایش ثبت' : 'ثبت با جزئیات',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        _label('نوع رویداد'),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'spontaneous', label: Text('خودبه‌خودی')),
              ButtonSegment(
                value: 'prompted_success',
                label: Text('با یادآور'),
              ),
              ButtonSegment(value: 'accident', label: Text('خیس شدن')),
            ],
            selected: {_type},
            onSelectionChanged: (val) => setState(() => _type = val.first),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'زمان',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.access_time_rounded, size: 16),
              label: Text(
                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
              ),
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
            ),
          ],
        ),
        _label('شدت فوریت'),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 1, label: Text('عادی')),
              ButtonSegment(value: 2, label: Text('متوسط')),
              ButtonSegment(value: 3, label: Text('شدید')),
            ],
            selected: {_urgency},
            onSelectionChanged: (v) => setState(() => _urgency = v.first),
          ),
        ),
        _label('حجم تقریبی'),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'small', label: Text('کم')),
              ButtonSegment(value: 'medium', label: Text('متوسط')),
              ButtonSegment(value: 'large', label: Text('زیاد')),
            ],
            selected: {_volume},
            onSelectionChanged: (v) => setState(() => _volume = v.first),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesCtrl,
          decoration: const InputDecoration(
            hintText: 'توضیحات تکمیلی (اختیاری)...',
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              // Edits stay on the log's own day; new entries belong to today.
              final base = widget.existing?.timestamp ?? DateTime.now();
              final dt = DateTime(
                base.year,
                base.month,
                base.day,
                _time.hour,
                _time.minute,
              );
              widget.onSave(
                _type,
                dt,
                _urgency,
                _volume,
                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              );
            },
            child: Text(isEditing ? 'ذخیره تغییرات' : 'ثبت'),
          ),
        ),
        if (widget.onDelete != null)
          SheetDeleteButton(onPressed: widget.onDelete!),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Component: Schedule Editor with Presets & Two-Way Custom Typed Input
// -----------------------------------------------------------------------------
class _ScheduleEditorSheet extends ConsumerStatefulWidget {
  final VoidingScheduleEntity schedule;

  const _ScheduleEditorSheet({required this.schedule});

  @override
  ConsumerState<_ScheduleEditorSheet> createState() =>
      _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends ConsumerState<_ScheduleEditorSheet> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _interval;
  late TextEditingController _customIntervalCtrl;

  @override
  void initState() {
    super.initState();
    final startParts = widget.schedule.startTime
        .split(':')
        .map(int.parse)
        .toList();
    final endParts = widget.schedule.endTime.split(':').map(int.parse).toList();
    _startTime = TimeOfDay(hour: startParts[0], minute: startParts[1]);
    _endTime = TimeOfDay(hour: endParts[0], minute: endParts[1]);
    _interval = widget.schedule.intervalMinutes;
    _customIntervalCtrl = TextEditingController(text: _interval.toString());
  }

  @override
  void dispose() {
    _customIntervalCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool get _isWindowValid =>
      _startTime.hour * 60 + _startTime.minute <
      _endTime.hour * 60 + _endTime.minute;

  bool get _isIntervalValid {
    final parsed = int.tryParse(_customIntervalCtrl.text.trim());
    return parsed != null && parsed > 0;
  }

  @override
  Widget build(BuildContext context) {
    final clinicalPresets = [45, 60, 75, 90, 105, 120, 150, 180];
    final canSave = _isWindowValid && _isIntervalValid;

    return AppSheetBody(
      children: [
        const Text(
          'تنظیم زمان‌بندی یادآور',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.wb_sunny_outlined, size: 16),
                label: Text('شروع: ${_formatTime(_startTime)}'),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bedtime_outlined, size: 16),
                label: Text('پایان: ${_formatTime(_endTime)}'),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (picked != null) setState(() => _endTime = picked);
                },
              ),
            ),
          ],
        ),
        if (!_isWindowValid)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'ساعت پایان باید بعد از ساعت شروع باشد.',
              style: TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ),
        const SizedBox(height: 18),
        const Text(
          'فاصله پیشنهادی (دقیقه)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: clinicalPresets.map((mins) {
            final isSelected = _interval == mins;
            return ChoiceChip(
              label: Text('$mins'),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primarySoft,
              onSelected: (_) {
                setState(() {
                  _interval = mins;
                  _customIntervalCtrl.text = mins.toString();
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _customIntervalCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'فاصله دلخواه',
            suffixText: 'دقیقه',
            isDense: true,
            errorText: _isIntervalValid
                ? null
                : 'یک عدد بزرگ‌تر از صفر وارد کنید',
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val.trim());
            setState(() {
              if (parsed != null && parsed > 0) _interval = parsed;
            });
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: !canSave
                ? null
                : () async {
                    final db = ref.read(databaseProvider);
                    final formattedStart = _formatTime(_startTime);
                    final formattedEnd = _formatTime(_endTime);

                    await (db.update(
                      db.voidingSchedules,
                    )..where((t) => t.id.equals(widget.schedule.id))).write(
                      VoidingSchedulesCompanion(
                        startTime: Value(formattedStart),
                        endTime: Value(formattedEnd),
                        intervalMinutes: Value(_interval),
                      ),
                    );

                    if (widget.schedule.isActive) {
                      await NotificationService.instance
                          .scheduleDailyVoidingSlots(
                            scheduleId: widget.schedule.id,
                            title: widget.schedule.title,
                            startTime: formattedStart,
                            endTime: formattedEnd,
                            intervalMinutes: _interval,
                          );
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text('ذخیره ($_interval دقیقه)'),
          ),
        ),
      ],
    );
  }
}
