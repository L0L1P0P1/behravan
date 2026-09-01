import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';
import 'widgets/jalali_calendar_grid.dart';

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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF0F172A),
          content: Text(
            isDry
                ? 'آفرین! یک شب خشک دیگر ثبت گردید 🌟'
                : 'وضعیت شب گذشته با موفقیت ثبت شد 🌙',
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                    'جزئیات تصادف شبانه (شب خیس)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'برای تخلیه ادرار در طول شب بیدار شد؟',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: wokeToPee,
                    activeColor: const Color(0xFF0284C7),
                    onChanged: (v) => setSheetState(() => wokeToPee = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'محدودیت مصرف مایعات عصر/شب رعایت شد؟',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: fluidRestriction,
                    activeColor: const Color(0xFF0284C7),
                    onChanged: (v) => setSheetState(() => fluidRestriction = v),
                  ),
                  const SizedBox(height: 12),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                      ),
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
                      child: const Text('ذخیره وضعیت شب خیس'),
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
      appBar: AppBar(title: const Text('پیگیری شب‌ادراری (Enuresis)')),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            children: [
              // Streaks Dashboard
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.wb_sunny_rounded,
                                color: Color(0xFF059669),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'رکورد فعلی خشک',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currentStreak روز',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                color: Color(0xFF0284C7),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'بهترین رکورد',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$longestStreak روز',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF075985),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Morning Log Buttons
              Text(
                'ثبت وضعیت بامداد برای تاریخ $selectedDateStr:',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _saveNightStatus(ref, isDry: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: selectedLog?.isDry == true
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF10B981),
                            width: selectedLog?.isDry == true ? 2.5 : 1.2,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.wb_sunny_rounded,
                              size: 32,
                              color: Color(0xFF059669),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'شب خشک (موفق)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF065F46),
                                fontSize: 13,
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
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _showWetNightDetailsDialog(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: selectedLog != null && !selectedLog.isDry
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFF59E0B),
                            width: selectedLog != null && !selectedLog.isDry
                                ? 2.5
                                : 1.2,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.nightlight_round,
                              size: 32,
                              color: Color(0xFFD97706),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'شب خیس (تصادف)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Calendar Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: JalaliCalendarGrid(
                  selectedDate: Jalali.fromDateTime(
                    _selectedDay ?? DateTime.now(),
                  ),
                  onDaySelected: (newDate) {
                    setState(() => _selectedDay = newDate.toDateTime());
                  },
                  logMap: logMap,
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('خطا: $e'),
      ),
    );
  }
}
