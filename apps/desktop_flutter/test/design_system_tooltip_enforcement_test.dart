import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all application tooltips go through the shared wrapper', () {
    final libDirectory = _findLibDirectory();
    final nativeTooltipPattern = RegExp(r'\bTooltip\s*\(');
    final offenders = <String>[];
    File? sharedWrapper;

    for (final entity in libDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final normalizedPath = entity.path.replaceAll('\\', '/');
      if (normalizedPath.endsWith(
        '/core/design/components/app_header_button.dart',
      )) {
        sharedWrapper = entity;
        continue;
      }

      if (nativeTooltipPattern.hasMatch(entity.readAsStringSync())) {
        offenders.add(normalizedPath);
      }
    }

    expect(sharedWrapper, isNotNull);
    expect(
      nativeTooltipPattern
          .allMatches(sharedWrapper!.readAsStringSync())
          .length,
      1,
      reason: 'AppTooltip must remain the single native Tooltip adapter.',
    );
    expect(
      offenders,
      isEmpty,
      reason: 'Use AppTooltip or AppTooltipIconButton instead of Tooltip.',
    );
  });
}

Directory _findLibDirectory() {
  final candidates = [
    Directory('lib'),
    Directory('apps/desktop_flutter/lib'),
  ];

  for (final candidate in candidates) {
    if (candidate.existsSync()) return candidate;
  }

  throw StateError('Could not locate the desktop Flutter lib directory.');
}
