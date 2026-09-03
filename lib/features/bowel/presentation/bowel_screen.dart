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

  Future<void> _saveBowelLog({
    required int bristolType,
    required DateTime timestamp,
    required int strainingLevel,
    required bool bloodPresent,
    required bool soilingAccident,
    String? notes,
  }) async {
    final db = ref.read(databaseProvider);
    final log = BowelLogsCompanion.insert(
      id: _uuid.v4(),
      timestamp: timestamp,
      bristolType: bristolType,
      strainingLevel: Value(strainingLevel),
      bloodPresent: Value(bloodPresent),
      soilingAccident: Value(soilingAccident),
      notes: Value(notes),
    );

    await db.into(db.bowelLogs).insert(log);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF0F172A),
          content: const Text('وضعیت دفع مدفوع با موفقیت ثبت شد ✅'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openBowelConfirmSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _BowelConfirmSheet(
        onConfirm:
            (bristolType, timestamp, straining, blood, soiling, notes) async {
              Navigator.pop(ctx);
              await _saveBowelLog(
                bristolType: bristolType,
                timestamp: timestamp,
                strainingLevel: straining,
                bloodPresent: blood,
                soilingAccident: soiling,
                notes: notes,
              );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bowelLogsAsync = ref.watch(bowelLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ثبت مدفوع و مقیاس بریستول')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: Color(0xFF059669),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'پیگیری سلامت گوارش و یبوست',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ثبت فرم مدفوع و فشار تخلیه، مبنای اصلی پایش و درمان مثانه است.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF047857),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _openBowelConfirmSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ثبت نوبت دفع مدفوع',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'انتخاب مقیاس بریستول، فشار و علائم',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          bowelLogsAsync.when(
            data: (logs) => _RecentBowelLogsAccordion(logs: logs),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطا: $e'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Unified BottomSheet with Direct Zoomable Bristol Chart & LTR Selector
// -----------------------------------------------------------------------------
class _BowelConfirmSheet extends StatefulWidget {
  final Function(
    int bristolType,
    DateTime timestamp,
    int strainingLevel,
    bool bloodPresent,
    bool soilingAccident,
    String? notes,
  )
  onConfirm;

  const _BowelConfirmSheet({required this.onConfirm});

  @override
  State<_BowelConfirmSheet> createState() => _BowelConfirmSheetState();
}

class _BowelConfirmSheetState extends State<_BowelConfirmSheet> {
  int _bristolType = 4;
  int _strainingLevel = 1;
  bool _bloodPresent = false;
  bool _soilingAccident = false;
  TimeOfDay _time = TimeOfDay.now();
  final _notesCtrl = TextEditingController();

  static const Map<int, _BristolInfo> _bristolData = {
    1: _BristolInfo(
      'نوع ۱: فندق‌های سفت و مجزا',
      'یبوست شدید (دفع بسیار سخت و دردناک)',
      Color(0xFF78350F),
      '🪨',
      'گلوله‌ای و خشک',
    ),
    2: _BristolInfo(
      'نوع ۲: سوسیسی توده‌ای و سفت',
      'یبوست خفیف (قطعات متصل به هم)',
      Color(0xFF92400E),
      '🥖',
      'توده‌ای و ناهموار',
    ),
    3: _BristolInfo(
      'نوع ۳: سوسیسی با سطح شیاردار',
      'طبیعی و سالم (دفع آسان)',
      Color(0xFF059669),
      '🌭',
      'دارای ترک روی سطح',
    ),
    4: _BristolInfo(
      'نوع ۴: مارپیچ، نرم و صاف',
      'ایده‌آل‌ترین حالت مدفوع کودکان',
      Color(0xFF10B981),
      '✨',
      'نرم، یکدست و منعطف',
    ),
    5: _BristolInfo(
      'نوع ۵: لکه‌های نرم با لبه مشخص',
      'کمبود فیبر (عبور نسبتاً سریع)',
      Color(0xFFD97706),
      '🍪',
      'نرم با لبه‌های واضح',
    ),
    6: _BristolInfo(
      'نوع ۶: قطعات پف‌کرده و کرکی',
      'اسهال خفیف یا التهاب گوارشی',
      Color(0xFFEA580C),
      '🥞',
      'خمیری و بدون شکل منظم',
    ),
    7: _BristolInfo(
      'نوع ۷: کاملاً آبکی بدون تکه جامد',
      'اسهال شدید (نیاز به توجه هیدراتاسیون)',
      Color(0xFFDC2626),
      '🌊',
      'مایع شفاف یا کدر',
    ),
  };

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _openFullScreenChartViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Image.asset(
                  'assets/images/bristol_chart.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            const Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'برای بزرگ‌نمایی تصویر را با دو انگشت بکشید',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentInfo = _bristolData[_bristolType]!;
    final bool hasCustomExtraInfo =
        _strainingLevel > 1 ||
        _bloodPresent ||
        _soilingAccident ||
        _notesCtrl.text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
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
            const SizedBox(height: 16),

            // Header & Zoom Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ثبت نوبت دفع (مقیاس بریستول)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF059669),
                  ),
                  icon: const Icon(Icons.zoom_in_rounded, size: 18),
                  label: const Text(
                    'بزرگ‌نمایی',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _openFullScreenChartViewer(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 1. Zoomable Bristol Chart (Directly Embedded, No Accordion)
            // 1. Zoomable Bristol Chart (Proportional Aspect Ratio & Rounded Image)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: AspectRatio(
                aspectRatio:
                    16 /
                    9, // Height scales automatically with the sheet's width
                child: GestureDetector(
                  onDoubleTap: () => _openFullScreenChartViewer(context),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.5,
                    clipBehavior: Clip.hardEdge,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/bristol_chart.png',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            'تصویر assets/images/bristol_chart.png یافت نشد.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. Selected Bristol Type Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: currentInfo.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: currentInfo.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: currentInfo.color.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      currentInfo.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentInfo.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: currentInfo.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentInfo.description,
                          style: const TextStyle(
                            fontSize: 11,
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

            const SizedBox(height: 12),

            // 3. Horizontal Type Selector (Explicitly Left-to-Right 1 -> 7)
            Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                height: 84,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final type = index + 1;
                    final data = _bristolData[type]!;
                    final isSelected = _bristolType == type;

                    return _BristolTypePill(
                      type: type,
                      data: data,
                      isSelected: isSelected,
                      onTap: () => setState(() => _bristolType = type),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 4. Time Selector Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'زمان وقوع رویداد:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text(_formatTime(_time)),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 5. Additional Information Dropdown (Straining, Flags, Notes)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasCustomExtraInfo
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  leading: Icon(
                    Icons.tune_rounded,
                    color: hasCustomExtraInfo
                        ? const Color(0xFF059669)
                        : const Color(0xFF64748B),
                    size: 22,
                  ),
                  title: const Text(
                    'اطلاعات و علائم تکمیلی (اختیاری)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  subtitle: Text(
                    hasCustomExtraInfo
                        ? 'فشار: ${_strainingLevel == 1 ? "عادی" : (_strainingLevel == 2 ? "متوسط" : "شدید")}${_bloodPresent ? " • خون" : ""}${_soilingAccident ? " • کثیفی لباس" : ""}'
                        : 'ثبت شدت زور زدن، خون، بی‌اختیاری و یادداشت',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasCustomExtraInfo
                          ? const Color(0xFF059669)
                          : const Color(0xFF94A3B8),
                      fontWeight: hasCustomExtraInfo
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'شدت فشار و زور زدن هنگام دفع:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 1, label: Text('عادی')),
                                ButtonSegment(value: 2, label: Text('متوسط')),
                                ButtonSegment(value: 3, label: Text('شدید')),
                              ],
                              selected: {_strainingLevel},
                              onSelectionChanged: (val) =>
                                  setState(() => _strainingLevel = val.first),
                            ),
                          ),
                          const Divider(height: 20, color: Color(0xFFE2E8F0)),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'مشاهده رگه‌های خون در مدفوع',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: _bloodPresent,
                            activeThumbColor: const Color(0xFFEF4444),
                            onChanged: (val) =>
                                setState(() => _bloodPresent = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'کثیف‌شدن لباس زیر (Encopresis)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: _soilingAccident,
                            activeThumbColor: const Color(0xFFF59E0B),
                            onChanged: (val) =>
                                setState(() => _soilingAccident = val),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _notesCtrl,
                            decoration: InputDecoration(
                              labelText: 'یادداشت یا مشاهده خاص (اختیاری)',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 6. Confirm & Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'تأیید و ثبت نهایی دفع',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  final now = DateTime.now();
                  final selectedDate = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    _time.hour,
                    _time.minute,
                  );
                  widget.onConfirm(
                    _bristolType,
                    selectedDate,
                    _strainingLevel,
                    _bloodPresent,
                    _soilingAccident,
                    _notesCtrl.text.trim().isEmpty
                        ? null
                        : _notesCtrl.text.trim(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Bristol Pill Widget (Adjusted for LTR Spacing)
// -----------------------------------------------------------------------------
class _BristolTypePill extends StatelessWidget {
  final int type;
  final _BristolInfo data;
  final bool isSelected;
  final VoidCallback onTap;

  const _BristolTypePill({
    required this.type,
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 74,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? data.color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? data.color : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              'نوع $type',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentBowelLogsAccordion extends StatelessWidget {
  final List<BowelLogEntity> logs;

  const _RecentBowelLogsAccordion({required this.logs});

  static const Map<int, String> _typeTitles = {
    1: 'فندق‌های سفت',
    2: 'سوسیسی توده‌ای',
    3: 'سوسیسی شیاردار',
    4: 'مارپیچ و نرم',
    5: 'تکه‌های نرم',
    6: 'خمیری و پف‌کرده',
    7: 'کاملاً آبکی',
  };

  @override
  Widget build(BuildContext context) {
    final displayLogs = logs.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = displayLogs[index];
                    final bool hasFlag =
                        log.bloodPresent || log.soilingAccident;
                    final typeName = _typeTitles[log.bristolType] ?? 'نامشخص';

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
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF059669,
                              ).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${log.bristolType}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'نوع ${log.bristolType} • $typeName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'فشار: ${log.strainingLevel == 1 ? "عادی" : (log.strainingLevel == 2 ? "متوسط" : "شدید")}'
                                  '${log.bloodPresent ? " • 🩸خون" : ""}'
                                  '${log.soilingAccident ? " • ⚠️کثیفی لباس" : ""}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: hasFlag
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                if (log.notes != null && log.notes!.isNotEmpty)
                                  Text(
                                    log.notes!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                borderRadius: BorderRadius.circular(8),
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
