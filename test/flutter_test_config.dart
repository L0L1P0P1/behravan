import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests lay out with the real fonts, so overflow checks reflect real text
/// widths rather than the block glyphs of the default test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final vazirmatn = FontLoader('Vazirmatn');
  for (final weight in const [
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black',
  ]) {
    vazirmatn.addFont(_loadFile('assets/fonts/Vazirmatn-FD-$weight.ttf'));
  }
  await vazirmatn.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(_loadFile(icons.path))).load();
  }

  await testMain();
}

Future<ByteData> _loadFile(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());
