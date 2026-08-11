import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all application tooltips go through the shared wrapper', () {
    final libDirectory = _findLibDirectory();
    final nativeTooltipPattern = RegExp(r'\bTooltip\s*\(');
    final offenders = <String>[];
    final nativeIconButtonTooltipOffenders = <String>[];
    File? sharedWrapper;

    for (final entity in libDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final normalizedPath = entity.path.replaceAll('\\', '/');
      final source = entity.readAsStringSync();
      if (normalizedPath.endsWith(
        '/core/design/components/app_header_button.dart',
      )) {
        sharedWrapper = entity;
        if (_hasIconButtonTooltipArgument(source)) {
          nativeIconButtonTooltipOffenders.add(normalizedPath);
        }
        continue;
      }

      if (nativeTooltipPattern.hasMatch(source)) {
        offenders.add(normalizedPath);
      }
      if (_hasIconButtonTooltipArgument(source)) {
        nativeIconButtonTooltipOffenders.add(normalizedPath);
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
    expect(
      nativeIconButtonTooltipOffenders,
      isEmpty,
      reason: 'IconButton.tooltip creates a native tooltip. Wrap the button '
          'with AppTooltip instead.',
    );
  });
}

bool _hasIconButtonTooltipArgument(String source) {
  final iconButtonPattern = RegExp(r'\bIconButton\s*\(');
  for (final match in iconButtonPattern.allMatches(source)) {
    final openParenthesis = source.indexOf('(', match.start);
    final closeParenthesis = _matchingParenthesis(source, openParenthesis);
    if (closeParenthesis == null) continue;
    final arguments = source.substring(openParenthesis + 1, closeParenthesis);
    if (RegExp(r'\btooltip\s*:').hasMatch(arguments)) return true;
  }
  return false;
}

int? _matchingParenthesis(String source, int openParenthesis) {
  var depth = 0;
  String? quote;
  var escaped = false;
  for (var index = openParenthesis; index < source.length; index++) {
    final character = source[index];
    if (quote != null) {
      if (escaped) {
        escaped = false;
      } else if (character == '\\') {
        escaped = true;
      } else if (character == quote) {
        quote = null;
      }
      continue;
    }
    if (character == "'" || character == '"') {
      quote = character;
      continue;
    }
    if (character == '(') {
      depth++;
    } else if (character == ')') {
      depth--;
      if (depth == 0) return index;
    }
  }
  return null;
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
