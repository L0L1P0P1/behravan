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

  Future<void> _quickLog(
    WidgetRef ref, {
    required String eventType,
    DateTime? customTimestamp,
    int urgency = 1,
    String volume = 'medium',
    String? notes,
  }) async {
    final db = ref.read(databaseProvider);
    final log = VoidingLogsCompanion.insert(
      id: _uuid.v4(),
      timestamp: customTimestamp ?? DateTime.now(),
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
                eventType == 'prompted_success'
                    ? Icons.check_circle
                    : Icons.timer,
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 10),
              Text(
                eventType == 'prompted_success'
                    ? 'آفرین! ثبت شد و تایمر بعدی فعال گردید'
                    : 'ثبت شد و زمان‌بندی بازنشانی شد',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

            final testPresets = [1, 2, 5, 10, 15, 30];
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
                    const SizedBox(height: 18),

                    const Row(
                      children: [
                        Icon(Icons.tune, size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Text(
                          'فواصل آزمایشی و تستی:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: testPresets.map((mins) {
                        final selected = intervalMinutes == mins;
                        return ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          label: Text('$mins د'),
                          selected: selected,
                          selectedColor: const Color(0xFFFEF3C7),
                          onSelected: (_) {
                            setSheetState(() {
                              intervalMinutes = mins;
                              customCtrl.text = mins.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

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
                        final selected = intervalMinutes == mins;
                        return ChoiceChip(
                          label: Text('$mins دقیقه'),
                          selected: selected,
                          selectedColor: const Color(0xFFE0F2FE),
                          onSelected: (_) {
                            setSheetState(() {
                              intervalMinutes = mins;
                              customCtrl.text = mins.toString();
                            });
                          },
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
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
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

  void _showDetailedLogSheet(BuildContext context) {
    String eventType = 'prompted_success';
    int urgency = 1;
    String volume = 'medium';
    TimeOfDay logTime = TimeOfDay.now();
    final notesCtrl = TextEditingController();

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
            String formatTime(TimeOfDay t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ثبت رویداد با جزئیات بالینی',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'زمان وقوع رویداد:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text(formatTime(logTime)),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: logTime,
                            );
                            if (picked != null) {
                              setSheetState(() => logTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'نوع مراجعه:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'prompted_success',
                        label: Text('یادآوری'),
                      ),
                      ButtonSegment(
                        value: 'spontaneous',
                        label: Text('خودبه‌خودی'),
                      ),
                      ButtonSegment(
                        value: 'accident',
                        label: Text('تصادفی / خیس'),
                      ),
                    ],
                    selected: {eventType},
                    onSelectionChanged: (val) =>
                        setSheetState(() => eventType = val.first),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'شدت فوریت (Urgency):',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Slider(
                    value: urgency.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    activeColor: const Color(0xFF0284C7),
                    label: urgency == 1
                        ? 'عادی'
                        : (urgency == 2 ? 'متوسط' : 'شدید'),
                    onChanged: (val) =>
                        setSheetState(() => urgency = val.toInt()),
                  ),
                  const Text(
                    'حجم تقریبی (Volume):',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'small', label: Text('کم')),
                      ButtonSegment(value: 'medium', label: Text('متوسط')),
                      ButtonSegment(value: 'large', label: Text('زیاد')),
                    ],
                    selected: {volume},
                    onSelectionChanged: (val) =>
                        setSheetState(() => volume = val.first),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'یادداشت یا مشاهده خاص (اختیاری)',
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final now = DateTime.now();
                        final customDate = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          logTime.hour,
                          logTime.minute,
                        );
                        _quickLog(
                          ref,
                          eventType: eventType,
                          customTimestamp: customDate,
                          urgency: urgency,
                          volume: volume,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );
                      },
                      child: const Text('ذخیره و ثبت در سیستم'),
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
    final logsAsync = ref.watch(voidingLogsProvider);
    final schedulesAsync = ref.watch(voidingSchedulesProvider);
    final progression = ref.watch(progressionEvaluationProvider);

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
          schedulesAsync.when(
            data: (schedules) {
              final s = schedules.isNotEmpty ? schedules.first : null;
              final bool isActive = s?.isActive ?? false;
              final logs = logsAsync.value ?? [];
              final targetTime = _calculateTargetTime(s, logs);

              return _HeroTimerWidget(
                schedule: s,
                isActive: isActive,
                targetTime: targetTime,
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

          if (canProgress) ...[
            const SizedBox(height: 14),
            Container(
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
                          '${progression.currentInterval} دقیقه ➔ ${progression.suggestedInterval} دقیقه (${(progression.successRate * 100).toInt()}% موفق)',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _applyProgression(
                      progression.currentInterval,
                      progression.suggestedInterval,
                    ),
                    child: const Text('اعمال', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          const Text(
            'ثبت سریع رویداد',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),

          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _quickLog(ref, eventType: 'prompted_success'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'توالت موفق (با یادآوری)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ثبت آنی و شروع شمارش معکوس نوبت بعدی',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  title: 'خودبه‌خودی',
                  subtitle: 'بدون آلارم',
                  onTap: () => _quickLog(ref, eventType: 'spontaneous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  title: 'خیس‌شدن',
                  subtitle: 'تصادف لباس',
                  onTap: () =>
                      _quickLog(ref, eventType: 'accident', urgency: 3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: const Text(
                'ثبت با جزئیات کامل (تنظیم زمان، حجم، فوریت)...',
              ),
              onPressed: () => _showDetailedLogSheet(context),
            ),
          ),

          const SizedBox(height: 14),

          // Collapsible Dropdown for Recent Voidings
          logsAsync.when(
            data: (logs) {
              final displayLogs = logs.take(5).toList();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final log = displayLogs[index];
                              final isAccident = log.eventType == 'accident';
                              final isSuccess =
                                  log.eventType == 'prompted_success';

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
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.12,
                                        ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          if (log.notes != null &&
                                              log.notes!.isNotEmpty)
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطا: $e'),
          ),
          const SizedBox(height: 24),
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
            // Force LTR on Clock Display
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

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: iconColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
