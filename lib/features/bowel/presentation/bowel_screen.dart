import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';

class BowelScreen extends ConsumerStatefulWidget {
  const BowelScreen({super.key});

  @override
  ConsumerState<BowelScreen> createState() => _BowelScreenState();
}

class _BowelScreenState extends ConsumerState<BowelScreen> {
  final _uuid = const Uuid();
  int _bristolType = 4;
  int _strainingLevel = 1;
  bool _bloodPresent = false;
  bool _soilingAccident = false;
  final _notesController = TextEditingController();

  final Map<int, _BristolInfo> _bristolData = {
    1: _BristolInfo(
      'نوع ۱: فندق‌های سخت',
      'یبوست شدید (گلوله‌ای و سفت)',
      Colors.brown.shade900,
      '🪨',
    ),
    2: _BristolInfo(
      'نوع ۲: سوسیس توده‌ای',
      'یبوست خفیف (توده‌ای)',
      Colors.brown.shade700,
      '🥖',
    ),
    3: _BristolInfo(
      'نوع ۳: سوسیس شیاردار',
      'طبیعی (با شیار سطحی)',
      Colors.green.shade800,
      '🌭',
    ),
    4: _BristolInfo(
      'نوع ۴: مار مانند و نرم',
      'ایده‌آل و کاملاً سالم',
      Colors.green.shade600,
      '✨',
    ),
    5: _BristolInfo(
      'نوع ۵: لکه‌های نرم با لبه مشخص',
      'کمبود فیبر غذایی',
      Colors.amber.shade700,
      '🍪',
    ),
    6: _BristolInfo(
      'نوع ۶: خمیری و بدون شکل',
      'اسهال خفیف (کرکی)',
      Colors.orange.shade800,
      '🥞',
    ),
    7: _BristolInfo(
      'نوع ۷: کاملاً آبکی',
      'اسهال شدید (مایع کامل)',
      Colors.red.shade700,
      '🌊',
    ),
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _logBowel(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final log = BowelLogsCompanion.insert(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      bristolType: _bristolType,
      strainingLevel: Value(_strainingLevel),
      bloodPresent: Value(_bloodPresent),
      soilingAccident: Value(_soilingAccident),
      notes: Value(
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );

    await db.into(db.bowelLogs).insert(log);
    _notesController.clear();
    setState(() {
      _strainingLevel = 1;
      _bloodPresent = false;
      _soilingAccident = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('وضعیت مدفوع ثبت شد ✅'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bowelLogsAsync = ref.watch(bowelLogsProvider);
    final currentInfo = _bristolData[_bristolType]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ثبت مدفوع و مقیاس بریستول',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Selected Bristol Highlight Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentInfo.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: currentInfo.color.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(currentInfo.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentInfo.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: currentInfo.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentInfo.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'انتخاب شکل مدفوع (مقیاس بریستول):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Horizontal Visual Stool Type Selector
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final type = index + 1;
                final data = _bristolData[type]!;
                final isSelected = _bristolType == type;

                return GestureDetector(
                  onTap: () => setState(() => _bristolType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 76,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? data.color : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? data.color : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: data.color.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(data.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          'نوع $type',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Clinical Observations Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'شدت زور زدن / فشار:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('بدون فشار')),
                      ButtonSegment(value: 2, label: Text('متوسط')),
                      ButtonSegment(value: 3, label: Text('شدید')),
                    ],
                    selected: {_strainingLevel},
                    onSelectionChanged: (val) =>
                        setState(() => _strainingLevel = val.first),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    title: const Text('خون در مدفوع دیده‌شد؟'),
                    value: _bloodPresent,
                    activeThumbColor: Colors.red,
                    onChanged: (val) => setState(() => _bloodPresent = val),
                  ),
                  SwitchListTile(
                    dense: true,
                    title: const Text(
                      'بی‌اختیاری یا کثیف‌شدن لباس زیر (انکوپرزیس)',
                    ),
                    value: _soilingAccident,
                    activeThumbColor: Colors.red,
                    onChanged: (val) => setState(() => _soilingAccident = val),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // One-Tap Action Submit Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'ثبت مدفوع',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _logBowel(ref),
            ),
          ),

          const Divider(height: 32),

          const Text(
            'تاریخچه ثبت‌های اخیر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // History Feed
          bowelLogsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'هنوز ثبتی انجام نشده است.',
                      style: TextStyle(color: Colors.grey),
                    ),
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
                  final info =
                      _bristolData[log.bristolType] ?? _bristolData[4]!;
                  final isAlert = log.bloodPresent || log.soilingAccident;

                  return ListTile(
                    tileColor: isAlert
                        ? Colors.red.shade50
                        : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isAlert
                            ? Colors.red.shade200
                            : Colors.grey.shade200,
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: info.color.withValues(alpha: 0.15),
                      child: Text(
                        info.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    title: Text(
                      info.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')} | فشار: ${log.strainingLevel == 1 ? "عادی" : (log.strainingLevel == 2 ? "متوسط" : "شدید")}${log.bloodPresent ? " • 🩸خون" : ""}${log.soilingAccident ? " • ⚠️کثیفی لباس" : ""}',
                    ),
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

class _BristolInfo {
  final String title;
  final String description;
  final Color color;
  final String emoji;
  const _BristolInfo(this.title, this.description, this.color, this.emoji);
}
