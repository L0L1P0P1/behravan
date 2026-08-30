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

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final voidingLogs = await db.select(db.voidingLogs).get();
    final enuresisLogs = await db.select(db.enuresisLogs).get();
    final bowelLogs = await db.select(db.bowelLogs).get();

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);

    final voidingFile = File('${dir.path}/voiding_logs_$timestamp.csv');
    final vBuffer = StringBuffer(
      'ID,Timestamp,EventType,UrgencyLevel,VolumeEstimation,Notes\n',
    );
    for (final v in voidingLogs) {
      vBuffer.writeln(
        '${v.id},${v.timestamp.toIso8601String()},${v.eventType},${v.urgencyLevel ?? ""},${v.volumeEstimation ?? ""},"${v.notes?.replaceAll('"', '""') ?? ""}"',
      );
    }
    await voidingFile.writeAsString(vBuffer.toString());

    final enuresisFile = File('${dir.path}/enuresis_logs_$timestamp.csv');
    final eBuffer = StringBuffer(
      'ID,Date,IsDry,WokeToPee,EveningFluidRestriction,Notes\n',
    );
    for (final e in enuresisLogs) {
      eBuffer.writeln(
        '${e.id},${e.date},${e.isDry},${e.wokeToPee},${e.eveningFluidRestriction},"${e.notes?.replaceAll('"', '""') ?? ""}"',
      );
    }
    await enuresisFile.writeAsString(eBuffer.toString());

    final bowelFile = File('${dir.path}/bowel_logs_$timestamp.csv');
    final bBuffer = StringBuffer(
      'ID,Timestamp,BristolType,StrainingLevel,BloodPresent,SoilingAccident,Notes\n',
    );
    for (final b in bowelLogs) {
      bBuffer.writeln(
        '${b.id},${b.timestamp.toIso8601String()},${b.bristolType},${b.strainingLevel},${b.bloodPresent},${b.soilingAccident},"${b.notes?.replaceAll('"', '""') ?? ""}"',
      );
    }
    await bowelFile.writeAsString(bBuffer.toString());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فایل‌های CSV در حافظه ذخیره شدند:\n${dir.path}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluation = ref.watch(progressionEvaluationProvider);
    final voidingCount = ref.watch(voidingLogsProvider).value?.length ?? 0;
    final enuresisCount = ref.watch(enuresisLogsProvider).value?.length ?? 0;
    final bowelCount = ref.watch(bowelLogsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تحلیل درمان و گزارش‌ها',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 3-Day Interval Evaluation Card
          if (evaluation != null) ...[
            _ProgressionCard(
              evaluation: evaluation,
              onApply: (oldInterval, newInterval) => _applySuggestedInterval(
                context,
                ref,
                oldInterval,
                newInterval,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Clinical Summary Counts Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'آمار کلی اطلاعات ثبت‌شده',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CountBadge(
                        label: 'ادرار روزانه',
                        count: voidingCount,
                        icon: Icons.water_drop,
                        color: Colors.blue,
                      ),
                      _CountBadge(
                        label: 'شب‌ادراری',
                        count: enuresisCount,
                        icon: Icons.nightlight_round,
                        color: Colors.indigo,
                      ),
                      _CountBadge(
                        label: 'مدفوع',
                        count: bowelCount,
                        icon: Icons.medical_services,
                        color: Colors.brown,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text(
              'اشتراک‌گذاری گزارش بالینی (PDF) برای پزشک',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _generatePdfReport(context, ref),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('خروجی خام داده‌ها (CSV)'),
            onPressed: () => _exportCsv(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ProgressionCard extends StatelessWidget {
  final IntervalEvaluationResult evaluation;
  final Function(int oldInterval, int newInterval) onApply;

  const _ProgressionCard({required this.evaluation, required this.onApply});

  Color _cardColor() {
    switch (evaluation.status) {
      case ProgressionStatus.progress:
        return Colors.green;
      case ProgressionStatus.regress:
        return Colors.orange;
      case ProgressionStatus.maintain:
        return Colors.blue;
      case ProgressionStatus.insufficientData:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _cardColor();
    final canApply =
        evaluation.status == ProgressionStatus.progress &&
        evaluation.suggestedInterval != evaluation.currentInterval;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                evaluation.status == ProgressionStatus.progress
                    ? Icons.trending_up
                    : (evaluation.status == ProgressionStatus.regress
                          ? Icons.trending_down
                          : Icons.insights),
                color: baseColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'ارزیابی پیشرفت ۳ روز اخیر',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(evaluation.successRate * 100).toInt()}% موفقیت',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            evaluation.recommendationMessage,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'فاصله فعلی: ${evaluation.currentInterval} دقیقه',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (canApply) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'پیشنهادی: ${evaluation.suggestedInterval} دقیقه',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
          if (canApply) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(
                  'اعمال افزایش به ${evaluation.suggestedInterval} دقیقه',
                ),
                onPressed: () => onApply(
                  evaluation.currentInterval,
                  evaluation.suggestedInterval,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _CountBadge({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
