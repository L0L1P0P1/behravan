import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/database/app_database.dart';
import '../application/clinical_report_pdf.dart';
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
      appBar: AppBar(title: const Text('گزارش و پیشرفت')),
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
                    icon: Icons.nightlight_rounded,
                    color: const Color(0xFF6366F1),
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
