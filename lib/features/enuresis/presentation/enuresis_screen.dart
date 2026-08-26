import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';

class EnuresisScreen extends ConsumerStatefulWidget {
  const EnuresisScreen({super.key});

  @override
  ConsumerState<EnuresisScreen> createState() => _EnuresisScreenState();
}

class _EnuresisScreenState extends ConsumerState<EnuresisScreen> {
  final _uuid = const Uuid();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isDry = true;
  bool _wokeToPee = false;
  bool _fluidRestriction = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLog(WidgetRef ref) async {
    if (_selectedDay == null) return;
    final db = ref.read(databaseProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    final existing = await (db.select(db.enuresisLogs)
          ..where((t) => t.date.equals(dateStr)))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.enuresisLogs)..where((t) => t.id.equals(existing.id)))
          .write(EnuresisLogsCompanion(
        isDry: Value(_isDry),
        wokeToPee: Value(_wokeToPee),
        eveningFluidRestriction: Value(_fluidRestriction),
        notes: Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
      ));
    } else {
      await db.into(db.enuresisLogs).insert(
            EnuresisLogsCompanion.insert(
              id: _uuid.v4(),
              date: dateStr,
              isDry: _isDry,
              wokeToPee: Value(_wokeToPee),
              eveningFluidRestriction: Value(_fluidRestriction),
              notes: Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
            ),
          );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ثبت شب‌ادراری برای $dateStr ذخیره شد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enuresisAsync = ref.watch(enuresisLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('پیگیری شب‌ادراری'),
        elevation: 0,
      ),
      body: enuresisAsync.when(
        data: (logs) {
          final Map<String, EnuresisLogEntity> logMap = {
            for (var l in logs) l.date: l
          };

          int currentStreak = 0;
          int longestStreak = 0;
          int tempStreak = 0;

          final today = DateTime.now();
          for (int i = 0; i < 60; i++) {
            final d = today.subtract(Duration(days: i));
            final dStr = DateFormat('yyyy-MM-dd').format(d);
            final log = logMap[dStr];
            if (log != null && log.isDry) {
              tempStreak++;
              if (i == 0 || currentStreak == i - 1) {
                currentStreak = tempStreak;
              }
              if (tempStreak > longestStreak) {
                longestStreak = tempStreak;
              }
            } else if (log != null && !log.isDry) {
              if (i == 0) currentStreak = 0;
              tempStreak = 0;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('رکورد فعلی', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 8),
                            Text('$currentStreak روز', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('بهترین رکورد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 8),
                            Text('$longestStreak روز', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar(
                    locale: 'fa_IR',
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    daysOfWeekHeight: 40,
                    rowHeight: 45,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                        _focusedDay = focusedDay;
                        final dStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
                        final existing = logMap[dStr];
                        if (existing != null) {
                          _isDry = existing.isDry;
                          _wokeToPee = existing.wokeToPee;
                          _fluidRestriction = existing.eveningFluidRestriction;
                          _notesController.text = existing.notes ?? '';
                        } else {
                          _isDry = true;
                          _wokeToPee = false;
                          _fluidRestriction = false;
                          _notesController.clear();
                        }
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        final dStr = DateFormat('yyyy-MM-dd').format(date);
                        final log = logMap[dStr];
                        if (log != null) {
                          return Positioned(
                            bottom: 1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: log.isDry ? Colors.green : Colors.amber.shade700,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                    ),
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
                      Text(
                        'ثبت برای: ${_selectedDay != null ? DateFormat('yyyy-MM-dd').format(_selectedDay!) : 'تاریخ را انتخاب کنید'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text('نتیجه اصلی:'),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('خشک (موفق)'), icon: Icon(Icons.wb_sunny, color: Colors.green)),
                          ButtonSegment(value: false, label: Text('خیس (تصادف)'), icon: Icon(Icons.nightlight_round, color: Colors.amber)),
                        ],
                        selected: {_isDry},
                        onSelectionChanged: (val) => setState(() => _isDry = val.first),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('برای ادرار بیدار شد؟'),
                        value: _wokeToPee,
                        onChanged: (val) => setState(() => _wokeToPee = val),
                      ),
                      SwitchListTile(
                        title: const Text('محدودیت مایعات شبانه رعایت شد؟'),
                        value: _fluidRestriction,
                        onChanged: (val) => setState(() => _fluidRestriction = val),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'یادداشت‌ها / زمینه',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('ذخیره ثبت شب'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _saveLog(ref),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Text('خطا: $e'),
      ),
    );
  }
}
