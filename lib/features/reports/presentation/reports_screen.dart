import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/database/app_database.dart';
import '../application/progression_service.dart';
import '../domain/progression_models.dart';
import 'widgets/celebration_dialog.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _applySuggestedInterval(
    BuildContext context,
    WidgetRef ref,
    int oldInterval,
    int newInterval,
  ) async {
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

    if (context.mounted) {
      await CelebrationDialog.show(
        context,
        oldInterval: oldInterval,
        newInterval: newInterval,
        onDismiss: () {},
      );
    }
  }

  Future<void> _generatePdfReport(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final voidingLogs = await db.select(db.voidingLogs).get();
    final enuresisLogs = await db.select(db.enuresisLogs).get();
    final bowelLogs = await db.select(db.bowelLogs).get();
    final evaluation = ref.read(progressionEvaluationProvider);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pw.PdfPageFormat.a4,
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Behravan Pediatric Voiding & Bowel Report',
              style: const pw.TextStyle(fontSize: 22),
            ),
          ),
          pw.Paragraph(
            text: 'Generated: ${DateTime.now().toString().substring(0, 19)}',
          ),
          if (evaluation != null) ...[
            pw.Header(level: 1, child: pw.Text('3-Day Adherence Assessment')),
            pw.Paragraph(
              text:
                  'Success Rate: ${(evaluation.successRate * 100).toInt()}% (${evaluation.successfulLogs}/${evaluation.totalLogs} events)\n'
                  'Current Interval: ${evaluation.currentInterval} min | Suggested: ${evaluation.suggestedInterval} min\n'
                  'Clinical Note: ${evaluation.recommendationMessage}',
            ),
            pw.SizedBox(height: 12),
          ],
          pw.Header(level: 1, child: pw.Text('Enuresis (Night) Logs')),
          pw.TableHelper.fromTextArray(
            headers: [
              'Date',
              'Outcome',
              'Woke to Pee',
              'Fluid Restriction',
              'Notes',
            ],
            data: enuresisLogs
                .map(
                  (e) => [
                    e.date,
                    e.isDry ? 'Dry' : 'Wet',
                    e.wokeToPee ? 'Yes' : 'No',
                    e.eveningFluidRestriction ? 'Yes' : 'No',
                    e.notes ?? '',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, child: pw.Text('Daytime Voiding Logs')),
          pw.TableHelper.fromTextArray(
            headers: ['Timestamp', 'Type', 'Urgency', 'Volume', 'Notes'],
            data: voidingLogs
                .map(
                  (v) => [
                    v.timestamp.toString().substring(0, 16),
                    v.eventType,
                    v.urgencyLevel?.toString() ?? '-',
                    v.volumeEstimation ?? '-',
                    v.notes ?? '',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, child: pw.Text('Bowel Logs (Bristol Scale)')),
          pw.TableHelper.fromTextArray(
            headers: [
              'Timestamp',
              'Bristol Type',
              'Straining',
              'Blood',
              'Soiling',
              'Notes',
            ],
            data: bowelLogs
                .map(
                  (b) => [
                    b.timestamp.toString().substring(0, 16),
                    'Type ${b.bristolType}',
                    b.strainingLevel.toString(),
                    b.bloodPresent ? 'Yes' : 'No',
                    b.soilingAccident ? 'Yes' : 'No',
                    b.notes ?? '',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'behravan_clinical_report.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluation = ref.watch(progressionEvaluationProvider);
    final voidingCount = ref.watch(voidingLogsProvider).value?.length ?? 0;
    final enuresisCount = ref.watch(enuresisLogsProvider).value?.length ?? 0;
    final bowelCount = ref.watch(bowelLogsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('تحلیل درمان و گزارش‌ها')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        children: [
          // 3-Day Progression Card
          if (evaluation != null) ...[
            _ProgressionBanner(
              evaluation: evaluation,
              onApply: (oldInterval, newInterval) => _applySuggestedInterval(
                context,
                ref,
                oldInterval,
                newInterval,
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Total Overview Grid
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'ادرار روزانه',
                  count: voidingCount,
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'شب‌ادراری',
                  count: enuresisCount,
                  icon: Icons.nightlight_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'مدفوع',
                  count: bowelCount,
                  icon: Icons.health_and_safety_rounded,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Primary Sharing Button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: const Color(0xFF0F172A),
            ),
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFF38BDF8),
            ),
            label: const Text('ایجاد و اشتراک PDF برای پزشک معالج'),
            onPressed: () => _generatePdfReport(context, ref),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
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
    final color = isProgress
        ? const Color(0xFF059669)
        : const Color(0xFF0284C7);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
              const Text(
                'تحلیل پیشرفت ۳ روز اخیر',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
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
                  '${(evaluation.successRate * 100).toInt()}% موفقیت',
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
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
          if (isProgress &&
              evaluation.suggestedInterval != evaluation.currentInterval) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                ),
                onPressed: () => onApply(
                  evaluation.currentInterval,
                  evaluation.suggestedInterval,
                ),
                child: Text(
                  'اعمال ارتقای فاصله به ${evaluation.suggestedInterval} دقیقه',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
