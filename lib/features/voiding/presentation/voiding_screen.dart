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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'برنامه ادرار روزانه',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Active Schedule Compact Status Header
          schedulesAsync.when(
            data: (schedules) {
              if (schedules.isEmpty) return const SizedBox.shrink();
              final s = schedules.first;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بازه فعال: ${s.startTime} تا ${s.endTime}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            'یادآوری هر ${s.intervalMinutes} دقیقه',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: s.isActive,
                      onChanged: (val) async {
                        final db = ref.read(databaseProvider);
                        await (db.update(
                          db.voidingSchedules,
                        )..where((t) => t.id.equals(s.id))).write(
                          VoidingSchedulesCompanion(isActive: Value(val)),
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
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Primary One-Tap Big Action Card
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

          // Secondary Quick Actions
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

          // Log History Feed
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
