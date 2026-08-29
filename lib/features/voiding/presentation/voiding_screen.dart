import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/database/app_database.dart';

class VoidingScreen extends ConsumerStatefulWidget {
  const VoidingScreen({super.key});

  @override
  ConsumerState<VoidingScreen> createState() => _VoidingScreenState();
}

class _VoidingScreenState extends ConsumerState<VoidingScreen> {
  final _uuid = const Uuid();
  String _selectedEventType = 'prompted_success';
  int _urgencyLevel = 1;
  String _volumeEstimation = 'medium';
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _logVoiding(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final log = VoidingLogsCompanion.insert(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      eventType: _selectedEventType,
      urgencyLevel: Value(_urgencyLevel),
      volumeEstimation: Value(_volumeEstimation),
      notes: Value(
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );

    await db.into(db.voidingLogs).insert(log);
    _notesController.clear();

    // Reset daytime timer on log
    await NotificationService.instance.resetTimerForActiveSchedules(db);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رویداد ادرار ثبت شد و تایمر یادآور بازنشانی شد ⏱️'),
        ),
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String formatTime(TimeOfDay t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Text('فاصله بین هر بار ادرار:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [60, 90, 120, 150, 180].map((mins) {
                      final selected = intervalMinutes == mins;
                      return ChoiceChip(
                        label: Text('$mins دقیقه'),
                        selected: selected,
                        onSelected: (_) =>
                            setSheetState(() => intervalMinutes = mins),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final formattedStart = formatTime(startTime);
                        final formattedEnd = formatTime(endTime);

                        await (db.update(
                          db.voidingSchedules,
                        )..where((t) => t.id.equals(schedule.id))).write(
                          VoidingSchedulesCompanion(
                            startTime: Value(formattedStart),
                            endTime: Value(formattedEnd),
                            intervalMinutes: Value(intervalMinutes),
                          ),
                        );

                        if (schedule.isActive) {
                          await NotificationService.instance
                              .scheduleDailyVoidingSlots(
                                scheduleId: schedule.id,
                                title: schedule.title,
                                startTime: formattedStart,
                                endTime: formattedEnd,
                                intervalMinutes: intervalMinutes,
                              );
                        }

                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('ذخیره و اعمال تغییرات'),
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

  String _eventTypeLabel(String type) {
    switch (type) {
      case 'prompted_success':
        return 'موفق (یادآوری)';
      case 'spontaneous':
        return 'خودبه‌خودی';
      case 'accident':
        return 'تصادفی';
      default:
        return type;
    }
  }

  String _urgencyLabel(int level) {
    switch (level) {
      case 1:
        return 'عادی';
      case 2:
        return 'متوسط';
      case 3:
        return 'شدید';
      default:
        return '$level';
    }
  }

  String _volumeLabel(String vol) {
    switch (vol) {
      case 'small':
        return 'کم';
      case 'medium':
        return 'متوسط';
      case 'large':
        return 'زیاد';
      default:
        return vol;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(voidingLogsProvider);
    final schedulesAsync = ref.watch(voidingSchedulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ادرار روزانه و یادآورها'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'برنامه زمان‌بندی ادرار',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.alarm_add),
                        onPressed: () {
                          NotificationService.instance.requestPermissions();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('مجوزهای اعلان و هشدار درخواست شد'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  schedulesAsync.when(
                    data: (schedules) {
                      if (schedules.isEmpty) {
                        return const Text('برنامه فعالی تنظیم نشده است.');
                      }
                      return Column(
                        children: schedules.map((s) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(
                                Icons.timer,
                                color: Colors.blue,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(s.title)),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () =>
                                      _showEditScheduleDialog(context, s),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'فعال: ${s.startTime} - ${s.endTime} (هر ${s.intervalMinutes} دقیقه)',
                            ),
                            trailing: Switch(
                              value: s.isActive,
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
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('خطا: $e'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ثبت سریع ادرار',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('نوع رویداد:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('موفق (یادآوری)'),
                        selected: _selectedEventType == 'prompted_success',
                        onSelected: (sel) => setState(
                          () => _selectedEventType = 'prompted_success',
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('خودبه‌خودی'),
                        selected: _selectedEventType == 'spontaneous',
                        onSelected: (sel) =>
                            setState(() => _selectedEventType = 'spontaneous'),
                      ),
                      ChoiceChip(
                        label: const Text('تصادفی'),
                        selected: _selectedEventType == 'accident',
                        onSelected: (sel) =>
                            setState(() => _selectedEventType = 'accident'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('شدت نیاز (۱ = عادی، ۳ = شدید/چکه):'),
                  Slider(
                    value: _urgencyLevel.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label: _urgencyLabel(_urgencyLevel),
                    onChanged: (val) =>
                        setState(() => _urgencyLevel = val.toInt()),
                  ),
                  const SizedBox(height: 8),
                  const Text('تقریب حجم:'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'small', label: Text('کم')),
                      ButtonSegment(value: 'medium', label: Text('متوسط')),
                      ButtonSegment(value: 'large', label: Text('زیاد')),
                    ],
                    selected: {_volumeEstimation},
                    onSelectionChanged: (val) =>
                        setState(() => _volumeEstimation = val.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'یادداشت‌ها (اختیاری)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('ثبت رویداد ادرار'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _logVoiding(ref),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ثبت‌های اخیر ادرار',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('هنوز ثبت ادراری وجود ندارد.'),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final isAccident = log.eventType == 'accident';
                  return Card(
                    color: isAccident ? Colors.red.shade50 : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAccident ? Colors.red : Colors.blue,
                        child: Icon(
                          isAccident ? Icons.warning : Icons.water_drop,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        _eventTypeLabel(log.eventType),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAccident ? Colors.red.shade900 : null,
                        ),
                      ),
                      subtitle: Text(
                        'زمان: ${log.timestamp.toString().substring(0, 16)} | حجم: ${_volumeLabel(log.volumeEstimation ?? '')} | شدت: ${_urgencyLabel(log.urgencyLevel ?? 1)}\n${log.notes ?? ''}',
                      ),
                      isThreeLine: log.notes != null,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('خطا: $e'),
          ),
        ],
      ),
    );
  }
}
