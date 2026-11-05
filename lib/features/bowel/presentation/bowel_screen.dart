import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_ui.dart';
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
    HapticFeedback.mediumImpact();
    final db = ref.read(databaseProvider);
    final newId = _uuid.v4();
    final log = BowelLogsCompanion.insert(
      id: newId,
      timestamp: timestamp,
      bristolType: bristolType,
      strainingLevel: Value(strainingLevel),
      bloodPresent: Value(bloodPresent),
      soilingAccident: Value(soilingAccident),
      notes: Value(notes),
    );

    await db.into(db.bowelLogs).insert(log);

    if (mounted) {
      AppToast.show(
        context,
        message: 'ثبت شد ✅',
        onUndo: () =>
            (db.delete(db.bowelLogs)..where((t) => t.id.equals(newId))).go(),
      );
    }
  }

  Future<void> _updateBowelLog(
    BowelLogEntity log, {
    required int bristolType,
    required DateTime timestamp,
    required int strainingLevel,
    required bool bloodPresent,
    required bool soilingAccident,
    String? notes,
  }) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.bowelLogs)..where((t) => t.id.equals(log.id))).write(
      BowelLogsCompanion(
        timestamp: Value(timestamp),
        bristolType: Value(bristolType),
        strainingLevel: Value(strainingLevel),
        bloodPresent: Value(bloodPresent),
        soilingAccident: Value(soilingAccident),
        notes: Value(notes),
      ),
    );

    if (mounted) AppToast.show(context, message: 'تغییرات ذخیره شد.');
  }

  Future<void> _deleteBowelLog(BowelLogEntity log) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.bowelLogs)..where((t) => t.id.equals(log.id))).go();

    if (!mounted) return;
    HapticFeedback.lightImpact();
    AppToast.show(
      context,
      message: 'ثبت حذف شد.',
      tone: ToastTone.neutral,
      onUndo: () => db.into(db.bowelLogs).insert(log),
    );
  }

  void _openBowelConfirmSheet(
    BuildContext context, {
    BowelLogEntity? existing,
  }) {
    showAppSheet(
      context,
      builder: (ctx) => _BowelConfirmSheet(
        existing: existing,
        onDelete: existing == null
            ? null
            : () {
                Navigator.pop(ctx);
                _deleteBowelLog(existing);
              },
        onConfirm:
            (bristolType, timestamp, straining, blood, soiling, notes) async {
              Navigator.pop(ctx);
              if (existing != null) {
                await _updateBowelLog(
                  existing,
                  bristolType: bristolType,
                  timestamp: timestamp,
                  strainingLevel: straining,
                  bloodPresent: blood,
                  soilingAccident: soiling,
                  notes: notes,
                );
                return;
              }
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
      appBar: AppBar(title: const Text('پیگیری مدفوع')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        children: [
          TapSurface(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _openBowelConfirmSheet(context),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
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
                      'ثبت نوبت جدید',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'نوع مدفوع، فشار و علائم',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'شکل مدفوع و میزان زور زدن به پزشک کمک می‌کند درمان مثانه را بهتر تنظیم کند.',
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          bowelLogsAsync.when(
            data: (logs) => _RecentBowelLogsCard(
              logs: logs,
              onLogTap: (log) => _openBowelConfirmSheet(context, existing: log),
            ),
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
  final BowelLogEntity? existing;
  final VoidCallback? onDelete;
  final Function(
    int bristolType,
    DateTime timestamp,
    int strainingLevel,
    bool bloodPresent,
    bool soilingAccident,
    String? notes,
  )
  onConfirm;

  const _BowelConfirmSheet({
    required this.onConfirm,
    this.existing,
    this.onDelete,
  });

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
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _bristolType = existing.bristolType;
      _strainingLevel = existing.strainingLevel;
      _bloodPresent = existing.bloodPresent;
      _soilingAccident = existing.soilingAccident;
      _time = TimeOfDay.fromDateTime(existing.timestamp);
      _notesCtrl.text = existing.notes ?? '';
    }
  }

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
    final isEditing = widget.existing != null;
    final bool hasCustomExtraInfo =
        _strainingLevel > 1 ||
        _bloodPresent ||
        _soilingAccident ||
        _notesCtrl.text.isNotEmpty;

    return AppSheetBody(
      children: [
        // Header & Zoom Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isEditing ? 'ویرایش ثبت' : 'مقیاس بریستول',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
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
                16 / 9, // Height scales automatically with the sheet's width
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
                          fontSize: 12,
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

        const SizedBox(height: 12),

        // 3. Type Selector (Explicitly Left-to-Right 1 -> 7, matching the chart)
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              for (var type = 1; type <= 7; type++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _BristolTypePill(
                      type: type,
                      data: _bristolData[type]!,
                      isSelected: _bristolType == type,
                      onTap: () => setState(() => _bristolType = type),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 4. Time Selector Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'زمان',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
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
        Material(
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: hasCustomExtraInfo
                  ? const Color(0xFFCBD5E1)
                  : AppColors.border,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: hasCustomExtraInfo,
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
                  fontSize: 12,
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
                          showSelectedIcon: false,
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
                        onChanged: (val) => setState(() => _bloodPresent = val),
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
                        onChanged: (val) =>
                            setState(() => _soilingAccident = val),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'یادداشت یا مشاهده خاص (اختیاری)',
                          filled: true,
                          fillColor: Colors.white,
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(isEditing ? 'ذخیره تغییرات' : 'ثبت'),
            onPressed: () {
              // Edits stay on the log's own day; new entries belong to today.
              final base = widget.existing?.timestamp ?? DateTime.now();
              final selectedDate = DateTime(
                base.year,
                base.month,
                base.day,
                _time.hour,
                _time.minute,
              );
              widget.onConfirm(
                _bristolType,
                selectedDate,
                _strainingLevel,
                _bloodPresent,
                _soilingAccident,
                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              );
            },
          ),
        ),
        if (widget.onDelete != null)
          SheetDeleteButton(onPressed: widget.onDelete!),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Bristol Pill Widget (All Seven Fit In One Row)
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? data.color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? data.color : AppColors.border,
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              '$type',
              style: TextStyle(
                fontSize: 14,
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

class _RecentBowelLogsCard extends StatelessWidget {
  final List<BowelLogEntity> logs;
  final ValueChanged<BowelLogEntity> onLogTap;

  const _RecentBowelLogsCard({required this.logs, required this.onLogTap});

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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'ثبت‌های اخیر',
            trailing: logs.length > 5 ? '۵ مورد از ${logs.length}' : null,
          ),
          if (logs.isEmpty)
            const EmptyState(
              icon: Icons.event_note_outlined,
              message: 'هنوز ثبتی انجام نشده است.\nاولین نوبت را از دکمه بالا ثبت کنید.',
            )
          else ...[
            const SizedBox(height: 2),
            const Text(
              'برای ویرایش یا حذف، روی هر مورد بزنید.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            for (final log in displayLogs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BowelLogRow(
                  log: log,
                  typeName: _typeTitles[log.bristolType] ?? 'نامشخص',
                  onTap: () => onLogTap(log),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _BowelLogRow extends StatelessWidget {
  final BowelLogEntity log;
  final String typeName;
  final VoidCallback onTap;

  const _BowelLogRow({
    required this.log,
    required this.typeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFlag = log.bloodPresent || log.soilingAccident;
    final straining = log.strainingLevel == 1
        ? 'عادی'
        : (log.strainingLevel == 2 ? 'متوسط' : 'شدید');

    return TapSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: hasFlag ? const Color(0xFFFECACA) : AppColors.border,
          width: hasFlag ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${log.bristolType}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.successDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'فشار: $straining'
                  '${log.bloodPresent ? " • 🩸خون" : ""}'
                  '${log.soilingAccident ? " • ⚠️کثیفی لباس" : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasFlag ? AppColors.danger : AppColors.muted,
                  ),
                ),
                if (log.notes != null && log.notes!.isNotEmpty)
                  Text(
                    log.notes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                PersianDateFormatter.clock(log.timestamp),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              Text(
                PersianDateFormatter.relativeDay(log.timestamp),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
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
  final String feature;

  const _BristolInfo(
    this.title,
    this.description,
    this.color,
    this.emoji,
    this.feature,
  );
}
