import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _generatePdfReport(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final voidingLogs = await db.select(db.voidingLogs).get();
    final enuresisLogs = await db.select(db.enuresisLogs).get();
    final bowelLogs = await db.select(db.bowelLogs).get();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pw.PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Behravan Pediatric Clinical Report',
                style: const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Paragraph(text: 'Generated on: ${DateTime.now().toString().substring(0, 19)}'),
          pw.SizedBox(height: 20),

          pw.Header(level: 1, child: pw.Text('Enuresis (Dry Night) Logs')),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Outcome', 'Woke to Pee', 'Fluid Restriction', 'Notes'],
            data: enuresisLogs.map((e) => [
                  e.date,
                  e.isDry ? 'Dry' : 'Wet',
                  e.wokeToPee ? 'Yes' : 'No',
                  e.eveningFluidRestriction ? 'Yes' : 'No',
                  e.notes ?? ''
                ]).toList(),
          ),
          pw.SizedBox(height: 20),

          pw.Header(level: 1, child: pw.Text('Daytime Voiding Logs')),
          pw.TableHelper.fromTextArray(
            headers: ['Timestamp', 'Event Type', 'Urgency', 'Volume', 'Notes'],
            data: voidingLogs.map((v) => [
                  v.timestamp.toString().substring(0, 16),
                  v.eventType,
                  v.urgencyLevel?.toString() ?? '-',
                  v.volumeEstimation ?? '-',
                  v.notes ?? ''
                ]).toList(),
          ),
          pw.SizedBox(height: 20),

          pw.Header(level: 1, child: pw.Text('Bowel Movement Logs (Bristol Stool Scale)')),
          pw.TableHelper.fromTextArray(
            headers: ['Timestamp', 'Bristol Type', 'Straining', 'Blood', 'Soiling', 'Notes'],
            data: bowelLogs.map((b) => [
                  b.timestamp.toString().substring(0, 16),
                  'Type ${b.bristolType}',
                  b.strainingLevel.toString(),
                  b.bloodPresent ? 'Yes' : 'No',
                  b.soilingAccident ? 'Yes' : 'No',
                  b.notes ?? ''
                ]).toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'behravan_clinical_report.pdf');
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final voidingLogs = await db.select(db.voidingLogs).get();

    final buffer = StringBuffer();
    buffer.writeln('ID,Timestamp,EventType,UrgencyLevel,VolumeEstimation,Notes');
    for (var v in voidingLogs) {
      buffer.writeln('${v.id},${v.timestamp},${v.eventType},${v.urgencyLevel},${v.volumeEstimation},"${v.notes ?? ''}"');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/voiding_logs.csv');
    await file.writeAsString(buffer.toString());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خروجی CSV ذخیره شد: ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voidingCount = ref.watch(voidingLogsProvider).value?.length ?? 0;
    final enuresisCount = ref.watch(enuresisLogsProvider).value?.length ?? 0;
    final bowelCount = ref.watch(bowelLogsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌ها و خروجی‌ها'),
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
                    'خلاصه اطلاعات بالینی',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.water_drop)),
                    title: const Text('ثبت‌های ادرار روزانه'),
                    trailing: Text('$voidingCount رکورد', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.nightlight_round)),
                    title: const Text('ثبت‌های شب‌ادراری'),
                    trailing: Text('$enuresisCount رکورد', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.medical_services)),
                    title: const Text('ثبت‌های مدفوع'),
                    trailing: Text('$bowelCount رکورد', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('ایجاد و اشتراک‌گذاری PDF برای متخصص'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _generatePdfReport(context, ref),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.table_chart),
            label: const Text('خروجی ثبت‌های ادرار به صورت CSV'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _exportCsv(context, ref),
          ),
        ],
      ),
    );
  }
}
