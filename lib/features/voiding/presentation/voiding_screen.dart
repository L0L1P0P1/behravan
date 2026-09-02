import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/database/app_database.dart';
import '../../reports/application/progression_service.dart';
import '../../reports/domain/progression_models.dart';
import '../../reports/presentation/widgets/celebration_dialog.dart';

class VoidingScreen extends ConsumerStatefulWidget {
  const VoidingScreen({super.key});

  @override
  ConsumerState<VoidingScreen> createState() => _VoidingScreenState();
}

class _VoidingScreenState extends ConsumerState<VoidingScreen> {
  final _uuid = const Uuid();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  DateTime? _calculateTargetTime(
    VoidingScheduleEntity? schedule,
    List<VoidingLogEntity> logs,
  ) {
    if (schedule == null || !schedule.isActive) return null;
    if (NotificationService.instance.currentNextAlarm != null) {
      return NotificationService.instance.currentNextAlarm;
    }

    final now = DateTime.now();
    if (logs.isNotEmpty) {
      final lastLogTime = logs.first.timestamp;
      final targetFromLastLog = lastLogTime.add(
        Duration(minutes: schedule.intervalMinutes),
      );
      if (targetFromLastLog.isAfter(now)) {
        return targetFromLastLog;
      }
    }
    return now.add(Duration(minutes: schedule.intervalMinutes));
  }

  Future<void> _saveVoidingLog({
    required String eventType,
    required DateTime timestamp,
    int urgency = 1,
    String volume = 'medium',
    String? notes,
  }) async {
    final db = ref.read(databaseProvider);
    final log = VoidingLogsCompanion.insert(
      id: _uuid.v4(),
      timestamp: timestamp,
      eventType: eventType,
      urgencyLevel: Value(urgency),
      volumeEstimation: Value(volume),
      notes: Value(notes),
    );

    await db.into(db.voidingLogs).insert(log);
    await NotificationService.instance.resetTimerForActiveSchedules(db);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF0F172A),
          content: Row(
            children: [
              Icon(
                eventType == 'accident'
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 10),
              Text(
                eventType == 'accident'
                    ? 'ثبت شد؛ نگران نباش، دفعه بعد بهتر می‌شه!'
                    : 'آفرین! رویداد ثبت و زمان‌بندی بازنشانی شد.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handlePrimaryPeeTap({
    required DateTime? targetTime,
    required bool isActive,
  }) async {
    String initialType = 'spontaneous';

    if (isActive && targetTime != null) {
      final now = DateTime.now();
      final diff = targetTime.difference(now);

      // Timer already reached or expired
      if (diff.isNegative || diff.inSeconds <= 0) {
        initialType = 'prompted_success';
      } else if (diff.inMinutes < 10) {
        // Less than 10 minutes left -> Encourage holding
        final remainingMinutes = diff.inMinutes > 0 ? diff.inMinutes : 1;
        final bool? proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B),
                  size: 28,
                ),
                SizedBox(width: 8),
                Text(
                  'کمی بیشتر صبر کن!',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: Text(
              'فقط $remainingMinutes دقیقه تا موعد دستشویی بعدی مانده! ⏳\n\n'
              'قهرمان، اگر می‌تونی چند دقیقه بیشتر صبر کن تا مثانه‌ات قوی‌تر بشه. آیا حتماً باید الان بری؟',
              style: const TextStyle(
                fontSize: 14,
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
                child: const Text('نه، دستشویی رفتم'),
              ),
            ],
          ),
        );

        if (proceed != true) return; // Child decided to wait
        initialType = 'spontaneous';
      }
    }

    if (!mounted) return;
    _openConfirmSheet(initialType: initialType);
  }

  void _openConfirmSheet({
    required String initialType,
    int defaultUrgency = 1,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _VoidingConfirmSheet(
        initialType: initialType,
        initialUrgency: defaultUrgency,
        onConfirm: (type, timestamp, urgency, volume, notes) async {
          Navigator.pop(ctx);
          await _saveVoidingLog(
            eventType: type,
            timestamp: timestamp,
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

  Future<void> _showEditScheduleDialog(
    BuildContext context,
    VoidingScheduleEntity schedule,
  ) async {
    final db = ref.read(databaseProvider);
    final startParts = schedule.startTime.split(':').map(int.parse).toList();
    final endParts = schedule.endTime.split(':').map(int.parse).toList();

    TimeOfDay startTime = TimeOfDay(hour: startParts[0], minute: startParts[1]);
    TimeOfDay endTime = TimeOfDay(hour: endParts[0], minute: endParts[1]);
    int intervalMinutes = schedule.intervalMinutes;
    final customCtrl = TextEditingController(text: intervalMinutes.toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String formatTime(TimeOfDay t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'تنظیم زمان‌بندی و ساعات یادآور ادرار',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                            label: Text('شروع: ${formatTime(startTime)}'),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setSheetState(() => startTime = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.nightlight_outlined,
                              size: 18,
                            ),
                            label: Text('پایان: ${formatTime(endTime)}'),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setSheetState(() => endTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'فواصل استاندارد درمانی (دقیقه):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: clinicalPresets.map((mins) {
                        return ChoiceChip(
                          label: Text('$mins دقیقه'),
                          selected: intervalMinutes == mins,
                          selectedColor: const Color(0xFFE0F2FE),
                          onSelected: (_) => setSheetState(() {
                            intervalMinutes = mins;
                            customCtrl.text = mins.toString();
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'فاصله دلخواه دستی (دقیقه)',
                        suffixText: 'دقیقه',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          setSheetState(() => intervalMinutes = parsed);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final parsed =
                              int.tryParse(customCtrl.text.trim()) ??
                              intervalMinutes;
                          final finalInterval = parsed > 0 ? parsed : 1;
                          final formattedStart = formatTime(startTime);
                          final formattedEnd = formatTime(endTime);

                          await (db.update(
                            db.voidingSchedules,
                          )..where((t) => t.id.equals(schedule.id))).write(
                            VoidingSchedulesCompanion(
                              startTime: Value(formattedStart),
                              endTime: Value(formattedEnd),
                              intervalMinutes: Value(finalInterval),
                            ),
                          );

                          final prefs = ref.read(sharedPreferencesProvider);
                          await prefs.setString(
                            'last_interval_change',
                            DateTime.now().toIso8601String(),
                          );

                          if (schedule.isActive) {
                            await NotificationService.instance
                                .scheduleDailyVoidingSlots(
                                  scheduleId: schedule.id,
                                  title: schedule.title,
                                  startTime: formattedStart,
                                  endTime: formattedEnd,
                                  intervalMinutes: finalInterval,
                                );
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(
                          'ذخیره و اعمال برنامه ($intervalMinutes دقیقه)',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(voidingLogsProvider);
    final schedulesAsync = ref.watch(voidingSchedulesProvider);
    final progression = ref.watch(progressionEvaluationProvider);

    final currentSchedule = schedulesAsync.value?.firstOrNull;
    final logs = logsAsync.value ?? [];
    final bool isActive = currentSchedule?.isActive ?? false;
    final targetTime = _calculateTargetTime(currentSchedule, logs);

    final now = DateTime.now();
    final diff = targetTime?.difference(now) ?? Duration.zero;
    final bool isCloseToAlarm =
        isActive &&
        targetTime != null &&
        !diff.isNegative &&
        diff.inMinutes < 10 &&
        diff.inSeconds > 0;
    final int remainingMinutes = diff.inMinutes > 0 ? diff.inMinutes : 1;

    final bool canProgress =
        progression != null &&
        progression.status == ProgressionStatus.progress &&
        progression.suggestedInterval > progression.currentInterval;

    return Scaffold(
      appBar: AppBar(
        title: const Text('برنامه زمان‌بندی ادرار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'مجوز اعلان‌ها',
            onPressed: () async {
              await NotificationService.instance.requestPermissions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('مجوزهای اعلان بازبینی شدند 🔔'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        children: [
          // 1. Hero Timer Card
          schedulesAsync.when(
            data: (schedules) {
              final s = schedules.firstOrNull;
              return _HeroTimerWidget(
                schedule: s,
                isActive: s?.isActive ?? false,
                targetTime: _calculateTargetTime(s, logs),
                onEditSchedule: s != null
                    ? () => _showEditScheduleDialog(context, s)
                    : null,
                onToggleActive: (val) async {
                  if (s == null) return;
                  final db = ref.read(databaseProvider);
                  await (db.update(db.voidingSchedules)
                        ..where((t) => t.id.equals(s.id)))
                      .write(VoidingSchedulesCompanion(isActive: Value(val)));

                  if (val) {
                    await NotificationService.instance
                        .scheduleDailyVoidingSlots(
                          scheduleId: s.id,
                          title: s.title,
                          startTime: s.startTime,
                          endTime: s.endTime,
                          intervalMinutes: s.intervalMinutes,
                        );
                  } else {
                    await NotificationService.instance.cancelScheduleAlarms(
                      s.id,
                    );
                  }
                },
              );
            },
            loading: () => const SizedBox(height: 180),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 2. Progression Upgrade Card (if eligible)
          if (canProgress) ...[
            const SizedBox(height: 14),
            _ProgressionAlertCard(
              currentInterval: progression.currentInterval,
              suggestedInterval: progression.suggestedInterval,
              successRate: progression.successRate,
              onApply: () => _applyProgression(
                progression.currentInterval,
                progression.suggestedInterval,
              ),
            ),
          ],

          // 3. Motivational Pre-Alarm Notice
          if (isCloseToAlarm) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'فقط $remainingMinutes دقیقه مانده! اگر می‌تونی کمی بیشتر نگه دار 🌟',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 4. Single Unified Voiding Action Button
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _handlePrimaryPeeTap(
              targetTime: targetTime,
              isActive: isActive,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ثبت رفتن به دستشویی',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'تأیید تخلیه ادرار و بازنشانی تایمر',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 5. Discreet Accident Option
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
              ),
              icon: const Icon(Icons.warning_amber_rounded, size: 16),
              label: const Text(
                'ثبت خیس شدن لباس (تصادف)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: () =>
                  _openConfirmSheet(initialType: 'accident', defaultUrgency: 3),
            ),
          ),

          const SizedBox(height: 12),

          // 6. Recent Logs Accordion
          logsAsync.when(
            data: (logs) => _RecentLogsAccordion(logs: logs),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطا: $e'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Unified Confirmation BottomSheet with Embedded Optional Details
// -----------------------------------------------------------------------------
class _VoidingConfirmSheet extends StatefulWidget {
  final String initialType;
  final int initialUrgency;
  final Function(
    String eventType,
    DateTime timestamp,
    int urgency,
    String volume,
    String? notes,
  )
  onConfirm;

  const _VoidingConfirmSheet({
    required this.initialType,
    required this.initialUrgency,
    required this.onConfirm,
  });

  @override
  State<_VoidingConfirmSheet> createState() => _VoidingConfirmSheetState();
}

class _VoidingConfirmSheetState extends State<_VoidingConfirmSheet> {
  late String _eventType;
  late int _urgency;
  String _volume = 'medium';
  TimeOfDay _time = TimeOfDay.now();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _eventType = widget.initialType;
    _urgency = widget.initialUrgency;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
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
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تأیید و ثبت رویداد ادرار',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // Mode Selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'prompted_success',
                  label: Text('با یادآوری'),
                ),
                ButtonSegment(value: 'spontaneous', label: Text('خودبه‌خودی')),
                ButtonSegment(value: 'accident', label: Text('تصادفی / خیس')),
              ],
              selected: {_eventType},
              onSelectionChanged: (val) =>
                  setState(() => _eventType = val.first),
            ),

            const SizedBox(height: 12),

            // Event Time Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'زمان وقوع رویداد:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text(_formatTime(_time)),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Embedded Optional Clinical Details (Expandable)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: Color(0xFF0284C7),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'اطلاعات تکمیلی (اختیاری)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    'شدت فوریت (Urgency):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Slider(
                    value: _urgency.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    activeColor: const Color(0xFF0284C7),
                    label: _urgency == 1
                        ? 'عادی'
                        : (_urgency == 2 ? 'متوسط' : 'شدید'),
                    onChanged: (val) => setState(() => _urgency = val.toInt()),
                  ),
                  const Text(
                    'حجم تقریبی (Volume):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'small', label: Text('کم')),
                      ButtonSegment(value: 'medium', label: Text('متوسط')),
                      ButtonSegment(value: 'large', label: Text('زیاد')),
                    ],
                    selected: {_volume},
                    onSelectionChanged: (val) =>
                        setState(() => _volume = val.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'یادداشت یا مشاهده خاص (اختیاری)',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Confirm & Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _eventType == 'accident'
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'تأیید و ثبت نهایی',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  final now = DateTime.now();
                  final selectedTimestamp = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    _time.hour,
                    _time.minute,
                  );
                  widget.onConfirm(
                    _eventType,
                    selectedTimestamp,
                    _urgency,
                    _volume,
                    _notesCtrl.text.trim().isEmpty
                        ? null
                        : _notesCtrl.text.trim(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Sub-Widgets (Decomposed for maintainability & clean Neovim folding)
// -----------------------------------------------------------------------------
class _ProgressionAlertCard extends StatelessWidget {
  final int currentInterval;
  final int suggestedInterval;
  final double successRate;
  final VoidCallback onApply;

  const _ProgressionAlertCard({
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
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'پیشنهاد افزایش فاصله! 🎉',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$currentInterval د ➔ $suggestedInterval د (${(successRate * 100).toInt()}% موفق)',
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: onApply,
            child: const Text('اعمال', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _HeroTimerWidget extends StatelessWidget {
  final VoidingScheduleEntity? schedule;
  final bool isActive;
  final DateTime? targetTime;
  final VoidCallback? onEditSchedule;
  final ValueChanged<bool> onToggleActive;

  const _HeroTimerWidget({
    required this.schedule,
    required this.isActive,
    required this.targetTime,
    required this.onEditSchedule,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = targetTime?.difference(now) ?? Duration.zero;
    final isAlarmReady = diff.isNegative && isActive;

    final hours = diff.inHours.clamp(0, 99);
    final minutes = (diff.inMinutes % 60).clamp(0, 59);
    final seconds = (diff.inSeconds % 60).clamp(0, 59);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF475569), const Color(0xFF334155)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF34D399)
                          : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'تایمر یادآوری فعال' : 'تایمر غیرفعال',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (onEditSchedule != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.settings_suggest_rounded,
                        color: Colors.white70,
                      ),
                      tooltip: 'تنظیم برنامه و فواصل زمانی',
                      onPressed: onEditSchedule,
                    ),
                  Switch(
                    value: isActive,
                    activeThumbColor: const Color(0xFF38BDF8),
                    activeTrackColor: const Color(0xFF0284C7),
                    onChanged: onToggleActive,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isAlarmReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.alarm_on_rounded,
                    color: Color(0xFFFCA5A5),
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'زمان دستشویی رفتن فرارسیده است!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hours > 0) ...[
                    _TimeDigitCard(
                      value: hours.toString().padLeft(2, '0'),
                      label: 'ساعت',
                    ),
                    const Text(
                      ' : ',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  _TimeDigitCard(
                    value: minutes.toString().padLeft(2, '0'),
                    label: 'دقیقه',
                  ),
                  const Text(
                    ' : ',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _TimeDigitCard(
                    value: seconds.toString().padLeft(2, '0'),
                    label: 'ثانیه',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          if (schedule != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${schedule!.startTime} – ${schedule!.endTime}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onEditSchedule,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF38BDF8),
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'هر ${schedule!.intervalMinutes} دقیقه',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimeDigitCard extends StatelessWidget {
  final String value;
  final String label;

  const _TimeDigitCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }
}

class _RecentLogsAccordion extends StatelessWidget {
  final List<VoidingLogEntity> logs;

  const _RecentLogsAccordion({required this.logs});

  @override
  Widget build(BuildContext context) {
    final displayLogs = logs.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F9FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ),
          title: const Text(
            'ثبت‌های اخیر ادرار',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            logs.isEmpty
                ? 'هنوز ثبتی انجام نشده'
                : (logs.length > 5
                      ? 'نمایش ۵ مورد از ${logs.length}'
                      : '${logs.length} رویداد ثبت‌شده'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          children: [
            if (logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'هنوز ثبتی در برنامه انجام نشده است.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = displayLogs[index];
                    final isAccident = log.eventType == 'accident';
                    final isSuccess = log.eventType == 'prompted_success';

                    final Color statusColor = isAccident
                        ? const Color(0xFFEF4444)
                        : (isSuccess
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0284C7));

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isAccident
                                  ? Icons.warning_rounded
                                  : (isSuccess
                                        ? Icons.check_circle_rounded
                                        : Icons.water_drop_rounded),
                              color: statusColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSuccess
                                      ? 'موفق با یادآوری'
                                      : (isAccident
                                            ? 'تصادف / خیس شدن'
                                            : 'مراجعه خودبه‌خودی'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (log.notes != null && log.notes!.isNotEmpty)
                                  Text(
                                    log.notes!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
