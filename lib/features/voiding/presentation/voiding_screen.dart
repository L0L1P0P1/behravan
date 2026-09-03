import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/database/app_database.dart';
import '../../reports/application/progression_service.dart';
import '../../reports/domain/progression_models.dart';
import '../../reports/presentation/widgets/celebration_dialog.dart';

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
  OverlayEntry? _toastEntry;

  @override
  void dispose() {
    _toastEntry?.remove();
    _toastEntry = null;
    super.dispose();
  }

  void _showAnimatedToast({
    required String message,
    required bool isAccident,
    required bool isPrompted,
    VoidCallback? onUndo,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    _toastEntry?.remove();
    _toastEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        isAccident: isAccident,
        isPrompted: isPrompted,
        duration: duration,
        onUndo: onUndo,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
          if (_toastEntry == entry) {
            _toastEntry = null;
          }
        },
      ),
    );

    _toastEntry = entry;
    Overlay.of(context).insert(entry);
  }

  DateTime? _calculateTargetTime(
    VoidingScheduleEntity? schedule,
    List<VoidingLogEntity> logs,
  ) {
    if (schedule == null || !schedule.isActive) return null;

    final now = DateTime.now();
    final interval = Duration(minutes: schedule.intervalMinutes);

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

    if (effectiveLastTime != null) {
      return effectiveLastTime.add(interval);
    }

    final nextAlarm = NotificationService.instance.currentNextAlarm;
    if (nextAlarm != null && nextAlarm.isAfter(now)) {
      return nextAlarm;
    }

    return now.add(interval);
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

  Future<void> _undoLog(String logId) async {
    setState(() {
      _lastManualResetTime = null;
    });

    final db = ref.read(databaseProvider);
    await (db.delete(db.voidingLogs)..where((t) => t.id.equals(logId))).go();
    await NotificationService.instance.resetTimerForActiveSchedules(db);

    if (!mounted) return;
    HapticFeedback.lightImpact();

    _showAnimatedToast(
      message: 'ثبت قبلی لغو شد.',
      isAccident: false,
      isPrompted: false,
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

    _showAnimatedToast(
      message: isAccident
          ? 'ثبت شد؛ قدم به قدم بهتر می‌شیم!'
          : (isPrompted
                ? 'آفرین! ثبت به‌موقع با یادآور ساعت ⏰'
                : 'رویداد ثبت و تایمر بازنشانی شد.'),
      isAccident: isAccident,
      isPrompted: isPrompted,
      onUndo: () => _undoLog(newId),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFF59E0B),
                size: 26,
              ),
              SizedBox(width: 8),
              Text(
                'کمی بیشتر صبر کن!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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

  void _showDetailedLogSheet({required String defaultType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _ClinicalLogDetailSheet(
        initialType: defaultType,
        onSave: (type, time, urgency, volume, notes) async {
          Navigator.pop(ctx);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'برنامه تمرین مثانه',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            onOpenDetailedEntry: () =>
                _showDetailedLogSheet(defaultType: 'spontaneous'),
          ),
          const SizedBox(height: 24),
          logsAsync.when(
            data: (items) => _VoidingDiaryCard(logs: items),
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
// Animated Toast Overlay with Guaranteed Self-Dismissal & Spring Transitions
// -----------------------------------------------------------------------------
class _ToastOverlay extends StatefulWidget {
  final String message;
  final bool isAccident;
  final bool isPrompted;
  final Duration duration;
  final VoidCallback? onUndo;
  final VoidCallback onDismissed;

  const _ToastOverlay({
    required this.message,
    required this.isAccident,
    required this.isPrompted,
    required this.duration,
    required this.onDismissed,
    this.onUndo,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animCtrl,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _animCtrl.forward();

    _dismissTimer = Timer(widget.duration, _triggerExit);
  }

  void _triggerExit() {
    _dismissTimer?.cancel();
    if (!mounted) return;
    _animCtrl.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomPadding + 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.horizontal,
              onDismissed: (_) {
                _dismissTimer?.cancel();
                widget.onDismissed();
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              (widget.isAccident
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981))
                                  .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isAccident
                              ? Icons.favorite_rounded
                              : Icons.check_circle_rounded,
                          color: widget.isAccident
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF059669),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (widget.onUndo != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            _triggerExit();
                            widget.onUndo!();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFBAE6FD),
                              ),
                            ),
                            child: const Text(
                              'لغو',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
        !isAlarmReady &&
        (schedule != null &&
            (schedule.intervalMinutes <= 2
                ? diff.inSeconds <= 25
                : diff.inSeconds <= 600));

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
                    isActive ? 'سیستم یادآور فعال' : 'یادآور غیرفعال',
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
                  activeThumbColor: const Color(0xFF0284C7),
                  activeTrackColor: const Color(0xFFBAE6FD),
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
                    value: isActive ? progress : 0,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAlarmReady
                          ? const Color(0xFFEF4444)
                          : (isHoldingPrompt
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF0284C7)),
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
                      ] else if (isAlarmReady) ...[
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 38,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'زمان تخلیه!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        Text(
                          '+${minutesLeft.toString().padLeft(2, '0')}:${secondsLeft.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
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
                      Text(
                        'هر ${schedule.intervalMinutes} دقیقه • ساعت ${schedule.startTime} تا ${schedule.endTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: onQuickSuccessTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
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
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onQuickAccidentTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ثبت خیس شدن',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onOpenDetailedEntry,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
          label: const Text(
            'ثبت با جزئیات کامل (حجم، فوریت، یادداشت)',
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
                    fontSize: 11,
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

  const _VoidingDiaryCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final sortedLogs = [...logs]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentLogs = sortedLogs.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'دفترچه ثبت امروز',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${logs.length} رویداد',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'هیچ موردی برای امروز ثبت نشده است.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentLogs.length,
              separatorBuilder: (_, __) => const Divider(
                height: 14,
                thickness: 0.8,
                color: Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final log = recentLogs[index];
                final isAccident = log.eventType == 'accident';
                final isSuccess = log.eventType == 'prompted_success';

                final color = isAccident
                    ? const Color(0xFFEF4444)
                    : (isSuccess
                          ? const Color(0xFF10B981)
                          : const Color(0xFF0284C7));

                final title = isSuccess
                    ? 'با یادآوری ساعت'
                    : (isAccident ? 'تصادفی / نشت' : 'خودبه‌خودی');

                return Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (log.notes != null && log.notes!.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          log.notes!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Component: Full Clinical Detail Entry BottomSheet
// -----------------------------------------------------------------------------
class _ClinicalLogDetailSheet extends StatefulWidget {
  final String initialType;
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

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
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
          const SizedBox(height: 18),
          const Text(
            'ثبت گزارش کامل',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'spontaneous', label: Text('خودبه‌خودی')),
              ButtonSegment(value: 'prompted_success', label: Text('با آلارم')),
              ButtonSegment(value: 'accident', label: Text('خیس شدن')),
            ],
            selected: {_type},
            onSelectionChanged: (val) => setState(() => _type = val.first),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'زمان دقیق وقوع:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
          const SizedBox(height: 12),
          const Text(
            'شدت فوریت (Urgency):',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Slider(
            value: _urgency.toDouble(),
            min: 1,
            max: 3,
            divisions: 2,
            activeColor: const Color(0xFF0284C7),
            label: _urgency == 1 ? 'عادی' : (_urgency == 2 ? 'متوسط' : 'شدید'),
            onChanged: (v) => setState(() => _urgency = v.toInt()),
          ),
          const Text(
            'حجم تقریبی:',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'small', label: Text('کم')),
              ButtonSegment(value: 'medium', label: Text('متوسط')),
              ButtonSegment(value: 'large', label: Text('زیاد')),
            ],
            selected: {_volume},
            onSelectionChanged: (v) => setState(() => _volume = v.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              hintText: 'توضیحات تکمیلی (اختیاری)...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                final now = DateTime.now();
                final dt = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  _time.hour,
                  _time.minute,
                );
                widget.onSave(
                  _type,
                  dt,
                  _urgency,
                  _volume,
                  _notesCtrl.text.trim().isEmpty
                      ? null
                      : _notesCtrl.text.trim(),
                );
              },
              child: const Text(
                'ثبت نهایی گزارش',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final clinicalPresets = [45, 60, 75, 90, 105, 120, 150, 180];

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            const Text(
              'تنظیم زمان‌بندی و ساعات یادآور',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
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
            const SizedBox(height: 18),
            const Text(
              'فواصل استاندارد پیشنهادی (دقیقه):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: clinicalPresets.map((mins) {
                final isSelected = _interval == mins;
                return ChoiceChip(
                  label: Text('$mins د'),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE0F2FE),
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
                labelText: 'یا فاصله دلخواه دستی (دقیقه)',
                suffixText: 'دقیقه',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val.trim());
                if (parsed != null && parsed > 0) {
                  setState(() => _interval = parsed);
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
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
                child: Text('ذخیره و اعمال ($_interval دقیقه)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
