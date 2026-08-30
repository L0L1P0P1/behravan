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

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );
  }

  Future<void> _saveNightStatus(
    WidgetRef ref, {
    required bool isDry,
    bool wokeToPee = false,
    bool fluidRestriction = false,
    String? notes,
  }) async {
    final db = ref.read(databaseProvider);
    final targetDate = _selectedDay ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDry
                ? 'آفرین! یک شب خشک دیگر ثبت شد 🌟'
                : 'وضعیت شب گذشته ثبت شد 🌙',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWetNightDetailsDialog(BuildContext context, WidgetRef ref) {
    bool wokeToPee = false;
    bool fluidRestriction = false;
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  const Text(
                    'جزئیات شب خیس (تصادف شبانه)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('برای ادرار بیدار شد؟'),
                    value: wokeToPee,
                    onChanged: (v) => setSheetState(() => wokeToPee = v),
                  ),
                  SwitchListTile(
                    title: const Text('محدودیت مایعات شبانه رعایت شد؟'),
                    value: fluidRestriction,
                    onChanged: (v) => setSheetState(() => fluidRestriction = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'یادداشت (اختیاری)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveNightStatus(
                          ref,
                          isDry: false,
                          wokeToPee: wokeToPee,
                          fluidRestriction: fluidRestriction,
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
    final enuresisAsync = ref.watch(enuresisLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'پیگیری شب‌ادراری',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: enuresisAsync.when(
        data: (logs) {
          final Map<String, EnuresisLogEntity> logMap = {
            for (var l in logs) l.date: l,
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
              if (i == 0 || currentStreak == i - 1) currentStreak = tempStreak;
              if (tempStreak > longestStreak) longestStreak = tempStreak;
            } else if (log != null && !log.isDry) {
              if (i == 0) currentStreak = 0;
              tempStreak = 0;
            }
          }

          final selectedDateStr = DateFormat(
            'yyyy-MM-dd',
          ).format(_selectedDay ?? today);
          final selectedLog = logMap[selectedDateStr];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Streak Stat Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'رکورد فعلی خشک ☀️',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currentStreak روز',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'بهترین رکورد 🏆',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$longestStreak روز',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Morning Log Action Prompts
              Text(
                'وضعیت شب برای تاریخ $selectedDateStr:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _saveNightStatus(ref, isDry: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: selectedLog?.isDry == true
                              ? Colors.green.shade100
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green,
                            width: selectedLog?.isDry == true ? 2.5 : 1,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.wb_sunny, size: 36, color: Colors.green),
                            SizedBox(height: 6),
                            Text(
                              'شب خشک (موفق)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showWetNightDetailsDialog(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: selectedLog != null && !selectedLog.isDry
                              ? Colors.amber.shade100
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.shade800,
                            width: selectedLog != null && !selectedLog.isDry
                                ? 2.5
                                : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.nightlight_round,
                              size: 36,
                              color: Colors.amber.shade900,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'شب خیس (تصادف)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Calendar Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar(
                    locale: 'fa_IR',
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    daysOfWeekHeight: 36,
                    rowHeight: 42,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = DateTime(
                          selectedDay.year,
                          selectedDay.month,
                          selectedDay.day,
                        );
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        final dStr = DateFormat('yyyy-MM-dd').format(date);
                        final log = logMap[dStr];
                        if (log != null) {
                          return Positioned(
                            bottom: 2,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: log.isDry
                                    ? Colors.green
                                    : Colors.amber.shade800,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('خطا: $e'),
      ),
    );
  }
}
