import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
    1: const _BristolInfo(
      'نوع ۱: فندق‌های سفت و مجزا',
      'یبوست شدید (دفع بسیار سخت و دردناک)',
      Color(0xFF78350F),
      '🪨',
      'گلوله‌ای و خشک',
    ),
    2: const _BristolInfo(
      'نوع ۲: سوسیسی توده‌ای و سفت',
      'یبوست خفیف (قطعات متصل به هم)',
      Color(0xFF92400E),
      '🥖',
      'توده‌ای و ناهموار',
    ),
    3: const _BristolInfo(
      'نوع ۳: سوسیسی با سطح شیاردار',
      'طبیعی و سالم (دفع آسان)',
      Color(0xFF059669),
      '🌭',
      'دارای ترک روی سطح',
    ),
    4: const _BristolInfo(
      'نوع ۴: مارپیچ، نرم و صاف',
      'ایده‌آل‌ترین حالت مدفوع کودکان',
      Color(0xFF10B981),
      '✨',
      'نرم، یکدست و منعطف',
    ),
    5: const _BristolInfo(
      'نوع ۵: لکه‌های نرم با لبه مشخص',
      'کمبود فیبر (عبور نسبتاً سریع)',
      Color(0xFFD97706),
      '🍪',
      'نرم با لبه‌های واضح',
    ),
    6: const _BristolInfo(
      'نوع ۶: قطعات پف‌کرده و کرکی',
      'اسهال خفیف یا التهاب گوارشی',
      Color(0xFFEA580C),
      '🥞',
      'خمیری و بدون شکل منظم',
    ),
    7: const _BristolInfo(
      'نوع ۷: کاملاً آبکی بدون تکه جامد',
      'اسهال شدید (نیاز به توجه هیدراتاسیون)',
      Color(0xFFDC2626),
      '🌊',
      'مایع شفاف یا کدر',
    ),
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showBristolChartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'جدول تصویری مقیاس بریستول',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://encrypted-tbn1.gstatic.com/licensed-image?q=tbn:ANd9GcSIaKFnOd_4-A5IBVcpck0kpGbh7JZrs0uS9yqDYAuKfoNZpV0rbFdffgbxTgtdxt6-MzHAbXCdVeP2vT0',
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Color(0xFF94A3B8),
                          size: 36,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'تصویر در دسترس نیست (اتصال اینترنت را بررسی کنید).',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'انواع ۳ و ۴ حالت استاندارد و نرمال هستند. انواع ۱ و ۲ نشان‌دهنده یبوست، و انواع ۶ و ۷ اسهال می‌باشند.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF0F172A),
          content: const Text('وضعیت مدفوع با موفقیت ثبت شد ✅'),
          duration: const Duration(seconds: 2),
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
        title: const Text('ثبت مدفوع و مقیاس بریستول'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'مشاهده جدول تصویری بریستول',
            onPressed: () => _showBristolChartDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: currentInfo.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: currentInfo.color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentInfo.color.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    currentInfo.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentInfo.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: currentInfo.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentInfo.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'انتخاب فرم مدفوع (مقیاس بریستول):',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.image_outlined, size: 16),
                label: const Text(
                  'جدول تصویری',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => _showBristolChartDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 96,
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
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? data.color : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? data.color
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: data.color.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(data.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          'نوع $type',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'شدت فشار و زور زدن هنگام دفع:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('راحت / عادی')),
                    ButtonSegment(value: 2, label: Text('متوسط')),
                    ButtonSegment(value: 3, label: Text('شدید')),
                  ],
                  selected: {_strainingLevel},
                  onSelectionChanged: (val) =>
                      setState(() => _strainingLevel = val.first),
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'مشاهده رگه‌های خون در مدفوع',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: _bloodPresent,
                  activeThumbColor: const Color(0xFFEF4444),
                  onChanged: (val) => setState(() => _bloodPresent = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'کثیف‌شدن لباس زیر (Encopresis)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: _soilingAccident,
                  activeThumbColor: const Color(0xFFF59E0B),
                  onChanged: (val) => setState(() => _soilingAccident = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('ثبت نوبت دفع مدفوع'),
              onPressed: () => _logBowel(ref),
            ),
          ),

          const SizedBox(height: 20),

          // Collapsible Dropdown for Recent Bowel Logs
          bowelLogsAsync.when(
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
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'سوابق ثبت مدفوع',
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
                              'هنوز ثبتی انجام نشده است.',
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
                              final info =
                                  _bristolData[log.bristolType] ??
                                  _bristolData[4]!;
                              final bool hasFlag =
                                  log.bloodPresent || log.soilingAccident;

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: hasFlag
                                        ? const Color(0xFFFECACA)
                                        : const Color(0xFFE2E8F0),
                                    width: hasFlag ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: info.color.withValues(
                                          alpha: 0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        info.emoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'نوع ${log.bristolType} • ${info.title.split(":")[1].trim()}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'فشار: ${log.strainingLevel == 1 ? "عادی" : (log.strainingLevel == 2 ? "متوسط" : "شدید")}${log.bloodPresent ? " • 🩸خون" : ""}${log.soilingAccident ? " • ⚠️کثیفی لباس" : ""}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: hasFlag
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFF64748B),
                                            ),
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

class _BristolInfo {
  final String title;
  final String description;
  final Color color;
  final String emoji;
  final String feature;

  const _BristolInfo(
    this.title,
    this.description,
    this.color,
    this.emoji,
    this.feature,
  );
}
