import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../../data/database/app_database.dart';

/// One table of the export: a header row, then typed cells. Cells are
/// [String], [num], [bool], [DateTime] (date and time) or [ExportDate]
/// (date only); null leaves the cell empty.
class ExportTable {
  final String name;
  final List<String> headers;
  final List<List<Object?>> rows;

  const ExportTable(this.name, this.headers, this.rows);
}

/// A calendar date with no time of day.
class ExportDate {
  final DateTime date;

  const ExportDate(this.date);
}

String _jalali(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
}

String _bristolCategory(int type) => switch (type) {
  <= 2 => 'Constipation',
  <= 5 => 'Normal',
  _ => 'Loose',
};

/// The three diaries as analysis-ready tables, oldest entry first. Codes stay
/// in English so the files load cleanly into spreadsheets and stats tools;
/// parents' notes are kept as written.
List<ExportTable> buildExportTables({
  required List<VoidingLogEntity> voidingLogs,
  required List<EnuresisLogEntity> enuresisLogs,
  required List<BowelLogEntity> bowelLogs,
}) {
  final voiding = [...voidingLogs]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final nights = [...enuresisLogs]..sort((a, b) => a.date.compareTo(b.date));
  final bowel = [...bowelLogs]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final weekday = DateFormat('EEEE', 'en_US');

  return [
    ExportTable(
      'Voiding',
      [
        'Timestamp',
        'Jalali Date',
        'Weekday',
        'Event Type',
        'Accident',
        'Urgency (1-3)',
        'Volume',
        'Notes',
      ],
      [
        for (final v in voiding)
          [
            v.timestamp,
            _jalali(v.timestamp),
            weekday.format(v.timestamp),
            v.eventType,
            v.eventType == 'accident',
            v.urgencyLevel,
            v.volumeEstimation,
            v.notes,
          ],
      ],
    ),
    ExportTable(
      'Enuresis',
      [
        'Morning Date',
        'Jalali Date',
        'Weekday',
        'Outcome',
        'Dry',
        'Woke To Void',
        'Evening Fluid Restriction',
        'Notes',
      ],
      [
        for (final n in nights)
          if (DateTime.tryParse(n.date) case final date?)
            [
              ExportDate(date),
              _jalali(date),
              weekday.format(date),
              n.isDry ? 'Dry' : 'Wet',
              n.isDry,
              n.wokeToPee,
              n.eveningFluidRestriction,
              n.notes,
            ],
      ],
    ),
    ExportTable(
      'Bowel',
      [
        'Timestamp',
        'Jalali Date',
        'Weekday',
        'Bristol Type (1-7)',
        'Bristol Category',
        'Straining (1-3)',
        'Blood Present',
        'Soiling Accident',
        'Notes',
      ],
      [
        for (final b in bowel)
          [
            b.timestamp,
            _jalali(b.timestamp),
            weekday.format(b.timestamp),
            b.bristolType,
            _bristolCategory(b.bristolType),
            b.strainingLevel,
            b.bloodPresent,
            b.soilingAccident,
            b.notes,
          ],
      ],
    ),
  ];
}

// --- CSV -------------------------------------------------------------------

String _csvCell(Object? value) {
  final text = switch (value) {
    null => '',
    DateTime d => DateFormat('yyyy-MM-dd HH:mm').format(d),
    ExportDate d => DateFormat('yyyy-MM-dd').format(d.date),
    bool b => b ? 'TRUE' : 'FALSE',
    _ => value.toString(),
  };
  return RegExp(r'[",\r\n]').hasMatch(text)
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

/// RFC 4180 CSV. The byte-order mark makes Excel read the Persian notes as
/// UTF-8 instead of the system code page.
Uint8List encodeCsv(ExportTable table) {
  final buffer = StringBuffer('﻿');
  for (final row in [table.headers, ...table.rows]) {
    buffer
      ..write(row.map(_csvCell).join(','))
      ..write('\r\n');
  }
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}

// --- XLSX ------------------------------------------------------------------

String _xml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    // XML 1.0 forbids most control characters, which free text could hold.
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

String _columnName(int index) {
  var name = '';
  for (var i = index + 1; i > 0; i = (i - 1) ~/ 26) {
    name = String.fromCharCode(65 + (i - 1) % 26) + name;
  }
  return name;
}

/// Days since Excel's epoch. Wall-clock fields are read as UTC so a DST
/// change can't shift a value by an hour.
double _excelSerial(DateTime d) {
  final wall = DateTime.utc(d.year, d.month, d.day, d.hour, d.minute, d.second);
  return wall.difference(DateTime.utc(1899, 12, 30)).inSeconds / 86400;
}

// Style ids in styles.xml: 1 bold header, 2 date and time, 3 date.
String _xlsxCell(String ref, Object? value, {bool header = false}) {
  return switch (value) {
    null => '',
    num n => '<c r="$ref"><v>$n</v></c>',
    bool b => '<c r="$ref" t="b"><v>${b ? 1 : 0}</v></c>',
    DateTime d => '<c r="$ref" s="2"><v>${_excelSerial(d)}</v></c>',
    ExportDate d => '<c r="$ref" s="3"><v>${_excelSerial(d.date)}</v></c>',
    _ =>
      '<c r="$ref" t="inlineStr"${header ? ' s="1"' : ''}>'
          '<is><t xml:space="preserve">${_xml(value.toString())}</t></is></c>',
  };
}

String _sheetXml(ExportTable table) {
  final rows = StringBuffer();
  for (final (r, row) in [table.headers, ...table.rows].indexed) {
    rows.write('<row r="${r + 1}">');
    for (final (c, value) in row.indexed) {
      rows.write(_xlsxCell('${_columnName(c)}${r + 1}', value, header: r == 0));
    }
    rows.write('</row>');
  }

  final cols = [
    for (final (c, header) in table.headers.indexed)
      '<col min="${c + 1}" max="${c + 1}" '
          'width="${header == 'Notes' ? 40 : (header.length + 4).clamp(12, 30)}" '
          'customWidth="1"/>',
  ].join();

  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetViews><sheetView workbookViewId="0">'
      '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
      '</sheetView></sheetViews>'
      '<cols>$cols</cols>'
      '<sheetData>$rows</sheetData>'
      '</worksheet>';
}

const _stylesXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<numFmts count="2">'
    '<numFmt numFmtId="164" formatCode="yyyy-mm-dd hh:mm"/>'
    '<numFmt numFmtId="165" formatCode="yyyy-mm-dd"/>'
    '</numFmts>'
    '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
    '<fills count="2"><fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill></fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="4">'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '</cellXfs>'
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
    '</styleSheet>';

/// A minimal Office Open XML workbook with one sheet per table.
Uint8List encodeXlsx(List<ExportTable> tables) {
  final archive = Archive();
  void add(String name, String content) =>
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(content)));

  final sheets = [for (var i = 1; i <= tables.length; i++) i];

  add(
    '[Content_Types].xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '${sheets.map((i) => '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>').join()}'
        '</Types>',
  );
  add(
    '_rels/.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
  );
  add(
    'xl/workbook.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets>${sheets.map((i) => '<sheet name="${_xml(tables[i - 1].name)}" sheetId="$i" r:id="rId$i"/>').join()}</sheets>'
        '</workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '${sheets.map((i) => '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$i.xml"/>').join()}'
        '<Relationship Id="rId${tables.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>',
  );
  add('xl/styles.xml', _stylesXml);
  for (final i in sheets) {
    add('xl/worksheets/sheet$i.xml', _sheetXml(tables[i - 1]));
  }

  return ZipEncoder().encodeBytes(archive);
}

// --- Sharing ---------------------------------------------------------------

enum ExportFormat { xlsx, csv }

/// Writes the export to the temporary directory and opens the share sheet:
/// one workbook for XLSX, one file per diary for CSV.
Future<void> shareDataExport({
  required ExportFormat format,
  required List<VoidingLogEntity> voidingLogs,
  required List<EnuresisLogEntity> enuresisLogs,
  required List<BowelLogEntity> bowelLogs,
}) async {
  final tables = buildExportTables(
    voidingLogs: voidingLogs,
    enuresisLogs: enuresisLogs,
    bowelLogs: bowelLogs,
  );
  final dir = await getTemporaryDirectory();
  final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<XFile> write(String name, Uint8List bytes, String mime) async {
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return XFile(file.path, mimeType: mime);
  }

  final files = switch (format) {
    ExportFormat.xlsx => [
      await write(
        'behravan_data_$stamp.xlsx',
        encodeXlsx(tables),
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
    ],
    ExportFormat.csv => [
      for (final t in tables)
        await write(
          'behravan_${t.name.toLowerCase()}_$stamp.csv',
          encodeCsv(t),
          'text/csv',
        ),
    ],
  };

  await SharePlus.instance.share(
    ShareParams(files: files, subject: 'Behravan diary export $stamp'),
  );
}
