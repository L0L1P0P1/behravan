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

  final Map<int, Map<String, String>> _bristolDescriptions = {
    1: {'title': 'نوع ۱: تکه‌های سخت جداگانه', 'desc': 'یبوست - سخت و غیرقابل رد (مثل گردو)'},
    2: {'title': 'نوع ۲: سوسیس‌شکل، ناهموار', 'desc': 'یبوست خفیف - سوسیس ناهموار'},
    3: {'title': 'نوع ۳: سوسیس با ترک‌ها', 'desc': 'عادی - سوسیس با ترک روی سطح'},
    4: {'title': 'نوع ۴: صاف و نرم', 'desc': 'ایده‌آل / عادی - صاف و نرم'},
    5: {'title': 'نوع ۵: تکه‌های نرم با لبه‌های مشخص', 'desc': 'کمبود فیبر - تکه‌های نرم'},
    6: {'title': 'نوع ۶: خمیری با لبه‌های نامنظم', 'desc': 'اسهال خفیف - تکه‌های پرزدار'},
    7: {'title': 'نوع ۷: کاملاً مایع', 'desc': 'اسهال - آبکی، بدون تکه جامد'},
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
      notes: Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
    );

    await db.into(db.bowelLogs).insert(log);
    _notesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مدفوع ثبت شد')),
      );
    }
  }

  Color _getBristolColor(int type) {
    if (type <= 2) return Colors.brown.shade800;
    if (type <= 4) return Colors.green.shade700;
    return Colors.amber.shade800;
  }

  String _strainingLabel(int level) {
    switch (level) {
      case 1: return 'بدون فشار';
      case 2: return 'متوسط';
      case 3: return 'شدید';
      default: return '$level';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bowelLogsAsync = ref.watch(bowelLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدفوع و مقیاس بریستول'),
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
                  const Text(
                    'انتخاب مقیاس بریستول',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _bristolDescriptions[_bristolType]!['title']!,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getBristolColor(_bristolType)),
                  ),
                  Text(
                    _bristolDescriptions[_bristolType]!['desc']!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final type = index + 1;
                        final isSelected = _bristolType == type;
                        return GestureDetector(
                          onTap: () => setState(() => _bristolType = type),
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? _getBristolColor(type).withValues(alpha: 0.2) : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected ? _getBristolColor(type) : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'نوع $type',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: _getBristolColor(type), fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  type <= 2 ? Icons.circle : (type <= 4 ? Icons.lens : Icons.water_drop),
                                  size: 20,
                                  color: _getBristolColor(type),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('شدت فشار:'),
                  Slider(
                    value: _strainingLevel.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label: _strainingLabel(_strainingLevel),
                    onChanged: (val) => setState(() => _strainingLevel = val.toInt()),
                  ),
                  SwitchListTile(
                    title: const Text('خون در مدفوع مشاهده شد؟'),
                    subtitle: const Text('خطوط یا مخلوط در مدفوع'),
                    value: _bloodPresent,
                    onChanged: (val) => setState(() => _bloodPresent = val),
                  ),
                  SwitchListTile(
                    title: const Text('تصادف مدفوع / انسکوپرسی؟'),
                    subtitle: const Text('تصادف مدفوع در لباس زیر'),
                    value: _soilingAccident,
                    onChanged: (val) => setState(() => _soilingAccident = val),
                  ),
                  const SizedBox(height: 8),
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
                      icon: const Icon(Icons.note_add),
                      label: const Text('ثبت مدفوع'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _logBowel(ref),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'ثبت‌های اخیر مدفوع',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          bowelLogsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('هنوز ثبت مدفوعی وجود ندارد.'),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Card(
                    color: log.soilingAccident || log.bloodPresent ? Colors.red.shade50 : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getBristolColor(log.bristolType),
                        child: Text(
                          'T${log.bristolType}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        _bristolDescriptions[log.bristolType]!['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'زمان: ${log.timestamp.toString().substring(0, 16)} | فشار: ${_strainingLabel(log.strainingLevel)}\n${log.bloodPresent ? '• خون مشاهده شد\n' : ''}${log.soilingAccident ? '• تصادف مدفوع\n' : ''}${log.notes ?? ''}',
                      ),
                      isThreeLine: true,
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
