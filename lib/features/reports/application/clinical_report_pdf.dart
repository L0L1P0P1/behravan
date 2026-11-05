import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;

import '../../../data/database/app_database.dart';
import '../domain/progression_models.dart';

const _persianFontAsset = 'assets/fonts/Vazirmatn-FD-Regular.ttf';

/// Builds the report shared with the treating clinician. Labels are English,
/// while the clinical note and parents' notes are Persian, so free text is
/// drawn with Vazirmatn: the PDF default font has no Persian glyphs.
Future<Uint8List> buildClinicalReportPdf({
  required List<VoidingLogEntity> voidingLogs,
  required List<EnuresisLogEntity> enuresisLogs,
  required List<BowelLogEntity> bowelLogs,
  required IntervalEvaluationResult? evaluation,
}) async {
  final persianFont = pw.Font.ttf(await rootBundle.load(_persianFontAsset));

  pw.Widget freeText(String text) => pw.Text(
    text,
    textDirection: pw.TextDirection.rtl,
    textAlign: pw.TextAlign.right,
    style: pw.TextStyle(font: persianFont, fontSize: 10),
  );

  pw.Widget table({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) return pw.Paragraph(text: 'No entries recorded.');
    final notesColumn = headers.length - 1;
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      cellBuilder: (column, cell, row) =>
          column == notesColumn ? freeText(cell.toString()) : null,
    );
  }

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
                'Current Interval: ${evaluation.currentInterval} min | Suggested: ${evaluation.suggestedInterval} min',
          ),
          pw.Text('Clinical Note:'),
          pw.SizedBox(height: 4),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: freeText(evaluation.recommendationMessage),
          ),
          pw.SizedBox(height: 12),
        ],
        pw.Header(level: 1, child: pw.Text('Enuresis (Night) Logs')),
        table(
          headers: [
            'Date',
            'Outcome',
            'Woke to Pee',
            'Fluid Restriction',
            'Notes',
          ],
          rows: enuresisLogs
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
        table(
          headers: ['Timestamp', 'Type', 'Urgency', 'Volume', 'Notes'],
          rows: voidingLogs
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
        table(
          headers: [
            'Timestamp',
            'Bristol Type',
            'Straining',
            'Blood',
            'Soiling',
            'Notes',
          ],
          rows: bowelLogs
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

  return pdf.save();
}
