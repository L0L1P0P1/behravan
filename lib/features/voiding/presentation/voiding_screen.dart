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
      notes: Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
    );

    await db.into(db.voidingLogs).insert(log);
    _notesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رویداد ادرار ثبت شد')),
      );
    }
  }

  String _eventTypeLabel(String type) {
    switch (type) {
      case 'prompted_success': return 'موفق (یادآوری)';
      case 'spontaneous': return 'خودبه‌خودی';
      case 'accident': return 'تصادفی';
      default: return type;
    }
  }

  String _urgencyLabel(int level) {
    switch (level) {
      case 1: return 'عادی';
      case 2: return 'متوسط';
      case 3: return 'شدید';
      default: return '$level';
    }
  }

  String _volumeLabel(String vol) {
    switch (vol) {
      case 'small': return 'کم';
      case 'medium': return 'متوسط';
      case 'large': return 'زیاد';
      default: return vol;
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.alarm_add),
                        onPressed: () {
                          NotificationService.instance.requestPermissions();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('_Alarm و notification permissions درخواست شد')),
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
                              child: const Icon(Icons.timer, color: Colors.blue),
                            ),
                            title: Text(s.title),
                            subtitle: Text('فعال: ${s.startTime} - ${s.endTime} (هر ${s.intervalMinutes} دقیقه)'),
                            trailing: Switch(
                              value: s.isActive,
                              onChanged: (val) async {
                                final db = ref.read(databaseProvider);
                                await (db.update(db.voidingSchedules)
                                      ..where((t) => t.id.equals(s.id)))
                                    .write(VoidingSchedulesCompanion(isActive: Value(val)));

                                if (val) {
                                  NotificationService.instance.scheduleVoidingReminder(
                                    id: s.hashCode,
                                    title: 'وقت ادرار است! 🚽',
                                    body: 'یادآوری زمان‌بندی ادرار برای فرزندتان.',
                                    scheduledTime: DateTime.now().add(Duration(minutes: s.intervalMinutes)),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('خطا: $e'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        onSelected: (sel) => setState(() => _selectedEventType = 'prompted_success'),
                      ),
                      ChoiceChip(
                        label: const Text('خودبه‌خودی'),
                        selected: _selectedEventType == 'spontaneous',
                        onSelected: (sel) => setState(() => _selectedEventType = 'spontaneous'),
                      ),
                      ChoiceChip(
                        label: const Text('تصادفی'),
                        selected: _selectedEventType == 'accident',
                        onSelected: (sel) => setState(() => _selectedEventType = 'accident'),
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
                    onChanged: (val) => setState(() => _urgencyLevel = val.toInt()),
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
                    onSelectionChanged: (val) => setState(() => _volumeEstimation = val.first),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
