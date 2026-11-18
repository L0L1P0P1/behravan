import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../../core/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/night_weather.dart';
import '../../../data/database/app_database.dart';
import '../../tutorial/presentation/tutorial_screen.dart';
import '../application/clinical_report_pdf.dart';
import '../application/data_export.dart';
import '../application/progression_service.dart';
import '../domain/progression_models.dart';
import 'widgets/celebration_dialog.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isExporting = false;
  ExportFormat? _exportingData;

  Future<void> _applySuggestedInterval(int oldInterval, int newInterval) async {
    final db = ref.read(databaseProvider);
    final schedules = await db.select(db.voidingSchedules).get();
    if (schedules.isEmpty) return;

    final schedule = schedules.first;
    await (db.update(db.voidingSchedules)
          ..where((t) => t.id.equals(schedule.id)))
        .write(VoidingSchedulesCompanion(intervalMinutes: Value(newInterval)));

    if (schedule.isActive) {
      await NotificationService.instance.scheduleDailyVoidingSlots(
        scheduleId: schedule.id,
        title: schedule.title,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        intervalMinutes: newInterval,
      );
    }

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      'last_interval_change',
      DateTime.now().toIso8601String(),
    );

    if (mounted) {
      await CelebrationDialog.show(
        context,
        oldInterval: oldInterval,
        newInterval: newInterval,
        onDismiss: () {},
      );
    }
  }

  Future<void> _generatePdfReport() async {
    setState(() => _isExporting = true);
    try {
      final db = ref.read(databaseProvider);
      final bytes = await buildClinicalReportPdf(
        voidingLogs: await db.select(db.voidingLogs).get(),
        enuresisLogs: await db.select(db.enuresisLogs).get(),
        bowelLogs: await db.select(db.bowelLogs).get(),
        evaluation: ref.read(progressionEvaluationProvider),
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'behravan_clinical_report.pdf',
      );
    } catch (e, st) {
      debugPrint('PDF export failed: $e\n$st');
      if (mounted) {
        AppToast.show(
          context,
          message: 'ساخت گزارش انجام نشد. دوباره تلاش کنید.',
          tone: ToastTone.neutral,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareData(ExportFormat format) async {
    setState(() => _exportingData = format);
    try {
      final db = ref.read(databaseProvider);
      await shareDataExport(
        format: format,
        voidingLogs: await db.select(db.voidingLogs).get(),
        enuresisLogs: await db.select(db.enuresisLogs).get(),
        bowelLogs: await db.select(db.bowelLogs).get(),
      );
    } catch (e, st) {
      debugPrint('Data export failed: $e\n$st');
      if (mounted) {
        AppToast.show(
          context,
          message: 'ساخت فایل انجام نشد. دوباره تلاش کنید.',
          tone: ToastTone.neutral,
        );
      }
    } finally {
      if (mounted) setState(() => _exportingData = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = ref.watch(progressionEvaluationProvider);
    final voidingLogs = ref.watch(voidingLogsProvider).value ?? const [];
    final enuresisLogs = ref.watch(enuresisLogsProvider).value ?? const [];
    final bowelLogs = ref.watch(bowelLogsProvider).value ?? const [];
    final totalLogs =
        voidingLogs.length + enuresisLogs.length + bowelLogs.length;

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekAgoKey = DateFormat('yyyy-MM-dd').format(weekAgo);
    final weekVoiding = voidingLogs.where((l) => l.timestamp.isAfter(weekAgo));
    final weekAccidents = weekVoiding.where((l) => l.eventType == 'accident');
    final weekNights = enuresisLogs.where(
      (l) => l.date.compareTo(weekAgoKey) > 0,
    );
    final weekDryNights = weekNights.where((l) => l.isDry);
    final weekBowel = bowelLogs.where((l) => l.timestamp.isAfter(weekAgo));

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش و پیشرفت'),
        actions: const [TutorialButton(topic: TutorialTopic.tips)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // 3-Day Progression Card
          if (evaluation != null) ...[
            _ProgressionBanner(
              evaluation: evaluation,
              onApply: _applySuggestedInterval,
            ),
            const SizedBox(height: 22),
          ],

          // Weekly Overview
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionHeader(title: '۷ روز اخیر'),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'ادرار',
                    value: '${weekVoiding.length}',
                    caption: weekAccidents.isEmpty
                        ? 'بدون خیس شدن'
                        : '${weekAccidents.length} بار خیس شدن',
                    icon: Icons.water_drop_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    title: 'شب خشک',
                    value: '${weekDryNights.length}',
                    caption: 'از ${weekNights.length} شب ثبت‌شده',
                    icon: Icons.wb_sunny_rounded,
                    color: AppColors.sunny,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    title: 'مدفوع',
                    value: '${weekBowel.length}',
                    caption: 'نوبت ثبت‌شده',
                    icon: Icons.health_and_safety_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Trends
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionHeader(title: 'روند پیشرفت'),
          ),
          const SizedBox(height: 10),
          _NightTrendCard(nights: enuresisLogs),
          const SizedBox(height: 10),
          _VoidingTrendCard(logs: voidingLogs),

          const SizedBox(height: 22),

          // Primary Sharing Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'گزارش برای پزشک',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalLogs == 0
                      ? 'بعد از اولین ثبت می‌توانید گزارش PDF بسازید.'
                      : 'همه $totalLogs ثبت در یک فایل PDF برای پزشک معالج.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isExporting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(
                    _isExporting ? 'در حال ساخت گزارش...' : 'ساخت و اشتراک PDF',
                  ),
                  onPressed: totalLogs == 0 || _isExporting
                      ? null
                      : _generatePdfReport,
                ),
                const SizedBox(height: 16),
                const Text(
                  'خروجی داده برای تحلیل',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'همه ثبت‌ها با تاریخ میلادی و شمسی، آماده اکسل و نرم‌افزارهای آماری.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final (format, label, icon) in const [
                      (ExportFormat.xlsx, 'اکسل', Icons.table_chart_rounded),
                      (ExportFormat.csv, 'CSV', Icons.description_outlined),
                    ]) ...[
                      if (format != ExportFormat.xlsx)
                        const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: _exportingData == format
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(icon, size: 18),
                          label: Text(label),
                          onPressed: totalLogs == 0 || _exportingData != null
                              ? null
                              : () => _shareData(format),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ProgressionBanner extends StatelessWidget {
  final IntervalEvaluationResult evaluation;
  final Function(int oldInterval, int newInterval) onApply;

  const _ProgressionBanner({required this.evaluation, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final isProgress = evaluation.status == ProgressionStatus.progress;
    final color = isProgress ? AppColors.success : AppColors.primary;
    // A rate over no data would read as a discouraging "0% success".
    final hasRate =
        evaluation.totalLogs > 0 &&
        evaluation.status != ProgressionStatus.insufficientData;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isProgress ? Icons.trending_up_rounded : Icons.insights_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'پیشرفت ۳ روز اخیر',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (hasRate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(evaluation.successRate * 100).toInt()}٪ موفقیت',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            evaluation.recommendationMessage,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              height: 1.6,
            ),
          ),
          if (isProgress &&
              evaluation.suggestedInterval != evaluation.currentInterval) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                onPressed: () => onApply(
                  evaluation.currentInterval,
                  evaluation.suggestedInterval,
                ),
                child: Text(
                  'افزایش فاصله به ${evaluation.suggestedInterval} دقیقه',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One column of a two-segment bar chart.
class _BarDatum {
  final String label;
  final int first;
  final int second;

  const _BarDatum(this.label, this.first, this.second);

  int get total => first + second;
}

/// Small stacked column chart: [first] sits on the baseline, [second] above
/// it, with a surface gap between them. Each column shows its total, and a
/// tap reveals the split.
class _StackedBars extends StatelessWidget {
  static const _plotHeight = 92.0;

  final List<_BarDatum> data;
  final Color firstColor;
  final Color secondColor;
  final String Function(_BarDatum) describe;
  final int minScale;

  const _StackedBars({
    required this.data,
    required this.firstColor,
    required this.secondColor,
    required this.describe,
    required this.minScale,
  });

  @override
  Widget build(BuildContext context) {
    final maxTotal = data.fold(minScale, (m, d) => d.total > m ? d.total : m);
    double heightOf(int v) => v == 0 ? 0 : (v / maxTotal) * _plotHeight;
    const radius = Radius.circular(4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final d in data)
          Expanded(
            child: Tooltip(
              message: describe(d),
              triggerMode: TooltipTriggerMode.tap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    d.total == 0 ? '–' : '${d.total}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: _plotHeight + 2,
                    width: 22,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.second > 0)
                          Container(
                            height: heightOf(d.second),
                            decoration: BoxDecoration(
                              color: secondColor,
                              borderRadius: const BorderRadius.vertical(
                                top: radius,
                              ),
                            ),
                          ),
                        if (d.first > 0 && d.second > 0)
                          const SizedBox(height: 2),
                        if (d.first > 0)
                          Container(
                            height: heightOf(d.first),
                            decoration: BoxDecoration(
                              color: firstColor,
                              borderRadius: d.second > 0
                                  ? null
                                  : const BorderRadius.vertical(top: radius),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 6),
                  Text(
                    d.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final List<(Widget, String)> items;

  const _ChartLegend({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final (marker, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              marker,
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

Widget _swatch(Color color) => Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(3),
  ),
);

class _TrendCard extends StatelessWidget {
  final String title;
  final String? headline;
  final Widget legend;
  final Widget chart;

  const _TrendCard({
    required this.title,
    required this.headline,
    required this.legend,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (headline != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                headline!,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 10),
          legend,
          const SizedBox(height: 14),
          chart,
        ],
      ),
    );
  }
}

/// Dry and wet nights in each of the last four weeks, oldest first so the
/// chart reads right to left like the text.
class _NightTrendCard extends StatelessWidget {
  final List<EnuresisLogEntity> nights;

  const _NightTrendCard({required this.nights});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final key = DateFormat('yyyy-MM-dd');
    const labels = ['۳ هفته پیش', '۲ هفته پیش', 'هفته پیش', 'این هفته'];

    final weeks = [
      for (var w = 3; w >= 0; w--)
        () {
          final from = key.format(
            DateTime(now.year, now.month, now.day - 7 * w - 6),
          );
          final to = key.format(DateTime(now.year, now.month, now.day - 7 * w));
          final inWeek = nights.where(
            (n) => n.date.compareTo(from) >= 0 && n.date.compareTo(to) <= 0,
          );
          return _BarDatum(
            labels[3 - w],
            inWeek.where((n) => n.isDry).length,
            inWeek.where((n) => !n.isDry).length,
          );
        }(),
    ];

    final thisWeek = weeks.last;
    final lastWeek = weeks[2];
    String? headline;
    if (thisWeek.total > 0 && lastWeek.total > 0) {
      final diff = thisWeek.first - lastWeek.first;
      headline = diff > 0
          ? '$diff شب آفتابی بیشتر از هفته پیش 🎉'
          : diff == 0
          ? 'به اندازه هفته پیش شب آفتابی داشتید.'
          : 'هفته سخت‌تری بود؛ ادامه بدهید، آفتاب برمی‌گردد.';
    }

    return _TrendCard(
      title: 'شب‌ها در ۴ هفته اخیر',
      headline: headline,
      legend: const _ChartLegend(
        items: [
          (NightWeatherIcon(isDry: true, size: 16), 'آفتابی (خشک)'),
          (NightWeatherIcon(isDry: false, size: 16), 'بارانی (خیس)'),
        ],
      ),
      chart: _StackedBars(
        data: weeks,
        firstColor: AppColors.sunny,
        secondColor: AppColors.rainy,
        minScale: 7,
        describe: (d) => '${d.first} شب آفتابی، ${d.second} شب بارانی',
      ),
    );
  }
}

/// Voids on each of the last seven days, split into dry voids and accidents.
class _VoidingTrendCard extends StatelessWidget {
  final List<VoidingLogEntity> logs;

  const _VoidingTrendCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];

    final data = [
      for (final day in days)
        () {
          final onDay = logs.where(
            (l) =>
                l.timestamp.year == day.year &&
                l.timestamp.month == day.month &&
                l.timestamp.day == day.day,
          );
          final accidents = onDay.where((l) => l.eventType == 'accident');
          return _BarDatum(
            day.day == now.day
                ? 'امروز'
                : Jalali.fromDateTime(day).formatter.wN.substring(0, 1),
            onDay.length - accidents.length,
            accidents.length,
          );
        }(),
    ];

    final total = data.fold(0, (s, d) => s + d.total);
    final dry = data.fold(0, (s, d) => s + d.first);

    return _TrendCard(
      title: 'ادرار در ۷ روز اخیر',
      headline: total == 0
          ? null
          : '${(dry * 100 / total).round()}٪ بدون خیس شدن',
      legend: _ChartLegend(
        items: [
          (_swatch(AppColors.primary), 'بدون خیس شدن'),
          (_swatch(AppColors.gentle), 'خیس شدن'),
        ],
      ),
      chart: _StackedBars(
        data: data,
        firstColor: AppColors.primary,
        secondColor: AppColors.gentle,
        minScale: 4,
        describe: (d) => '${d.first} بار موفق، ${d.second} بار خیس شدن',
      ),
    );
  }
}
