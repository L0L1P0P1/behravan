import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
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

  String _formatRemainingTime(DateTime? targetTime) {
    if (targetTime == null) return 'یادآور غیرفعال است';
    final now = DateTime.now();
    final diff = targetTime.difference(now);

    if (diff.isNegative) {
      return '🔔 زمان دستشویی فرارسیده!';
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} مانده تا آلارم';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} مانده تا آلارم';
  }

  Future<void> _quickLog(
    WidgetRef ref, {
    required String eventType,
    int urgency = 1,
    String volume = 'medium',
    String? notes,
  }) async {
    final db = ref.read(databaseProvider);
    final log = VoidingLogsCompanion.insert(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
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
          content: Text(
            eventType == 'prompted_success'
                ? 'آفرین! ثبت شد و تایمر بعدی فعال شد 🌟'
                : 'ثبت شد و تایمر بازنشانی شد ⏱️',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                top: 24,
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
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تنظیم زمان‌بندی: ${schedule.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.wb_sunny_outlined),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.nightlight_outlined),
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
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Icon(
                          Icons.bug_report,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'فواصل آزمایشی و تستی (دقیقه):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
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
                          label: Text('$mins م'),
                          selected: selected,
                          selectedColor: Colors.orange.shade100,
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
                      'فواصل استاندارد بالینی:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
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
                      decoration: const InputDecoration(
                        labelText: 'فاصله دلخواه دستی (دقیقه)',
                        suffixText: 'دقیقه',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          setSheetState(() => intervalMinutes = parsed);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
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
                          'ذخیره و فعال‌سازی ($intervalMinutes دقیقه)',
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
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ثبت با جزئیات کامل',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
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
                      ButtonSegment(value: 'accident', label: Text('تصادفی')),
                    ],
                    selected: {eventType},
                    onSelectionChanged: (val) =>
                        setSheetState(() => eventType = val.first),
                  ),
                  const SizedBox(height: 16),
                  const Text('میزان فوریت:'),
                  Slider(
                    value: urgency.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label: urgency == 1
                        ? 'عادی'
                        : (urgency == 2 ? 'متوسط' : 'شدید'),
                    onChanged: (val) =>
                        setSheetState(() => urgency = val.toInt()),
                  ),
                  const Text('حجم تقریبی:'),
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
                    decoration: const InputDecoration(
                      labelText: 'یادداشت (اختیاری)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _quickLog(
                          ref,
                          eventType: eventType,
                          urgency: urgency,
                          volume: volume,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );
                      },
                      child: const Text('ذخیره'),
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
        title: const Text(
          'برنامه ادرار روزانه',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'درخواست مجوزهای هشدار دقیق',
            onPressed: () async {
              await NotificationService.instance.requestPermissions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('مجوزهای هشدار و اعلان درخواست شد 🔔'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Responsive Overflow-Free Countdown Card
          schedulesAsync.when(
            data: (schedules) {
              final s = schedules.isNotEmpty ? schedules.first : null;
              final bool isActive = s?.isActive ?? false;
              final logs = logsAsync.value ?? [];
              final targetTime = _calculateTargetTime(s, logs);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [Colors.blue.shade700, Colors.blue.shade900]
                        : [Colors.grey.shade700, Colors.grey.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? Colors.blue : Colors.black).withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar (Constrained Row)
                    Row(
                      children: [
                        Icon(
                          isActive
                              ? Icons.timer_outlined
                              : Icons.timer_off_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isActive ? 'یادآور فعال است' : 'یادآور خاموش است',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (s != null) ...[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.tune,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'تنظیم برنامه',
                            onPressed: () =>
                                _showEditScheduleDialog(context, s),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: isActive,
                              activeTrackColor: Colors.greenAccent.shade400,
                              onChanged: (val) async {
                                final db = ref.read(databaseProvider);
                                await (db.update(
                                  db.voidingSchedules,
                                )..where((t) => t.id.equals(s.id))).write(
                                  VoidingSchedulesCompanion(
                                    isActive: Value(val),
                                  ),
                                );
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
                                  await NotificationService.instance
                                      .cancelScheduleAlarms(s.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Countdown Display
                    Text(
                      isActive
                          ? _formatRemainingTime(targetTime)
                          : 'برای شروع یادآوری، کلید بالا را روشن کنید',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isActive ? 20 : 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (isActive && s != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'بازه: ${s.startTime} تا ${s.endTime} | هر ${s.intervalMinutes} دقیقه',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Progression Offer Banner
          if (canProgress) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.star, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ارتقای فاصله ادرار آماده است! 🚀',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${progression.currentInterval} دقیقه ➔ ${progression.suggestedInterval} دقیقه (${(progression.successRate * 100).toInt()}% موفق)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => _applyProgression(
                      progression.currentInterval,
                      progression.suggestedInterval,
                    ),
                    child: const Text(
                      'افزایش',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Big One-Tap Action Card
          Card(
            elevation: 0,
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.green.shade200),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _quickLog(ref, eventType: 'prompted_success'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green),
                    SizedBox(height: 8),
                    Text(
                      'رفتم دستشویی (موفق)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ثبت سریع و شروع فاصله بعدی',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.bolt, color: Colors.amber),
                  label: const Text('خودبه‌خودی'),
                  onPressed: () => _quickLog(ref, eventType: 'spontaneous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                  ),
                  label: const Text('تصادف/خیس'),
                  onPressed: () =>
                      _quickLog(ref, eventType: 'accident', urgency: 3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          TextButton.icon(
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('ثبت با جزئیات بیشتر (حجم، فوریت، یادداشت)...'),
            onPressed: () => _showDetailedLogSheet(context),
          ),

          const Divider(height: 32),

          const Text(
            'رویدادهای ثبت‌شده امروز',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Text(
                    'هنوز ثبتی انجام نشده است.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final isAccident = log.eventType == 'accident';
                  final isSuccess = log.eventType == 'prompted_success';

                  return ListTile(
                    tileColor: isAccident
                        ? Colors.red.shade50
                        : (isSuccess
                              ? Colors.green.shade50
                              : Colors.grey.shade100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      isAccident
                          ? Icons.warning
                          : (isSuccess ? Icons.check_circle : Icons.water_drop),
                      color: isAccident
                          ? Colors.red
                          : (isSuccess ? Colors.green : Colors.blue),
                    ),
                    title: Text(
                      isSuccess
                          ? 'موفق با یادآوری'
                          : (isAccident ? 'تصادف' : 'خودبه‌خودی'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: log.notes != null
                        ? const Icon(Icons.note, size: 16, color: Colors.grey)
                        : null,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطا: $e'),
          ),
        ],
      ),
    );
  }
}
