import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('documents the approved keyboard behavior', (tester) async {
    await pumpDesignSystemGallery(tester);

    final section = find.text('معايير لوحة المفاتيح');
    await reveal(tester, section);

    for (final shortcut in [
      'Enter',
      'Tab',
      'Shift + Tab',
      'Ctrl + S',
      'Ctrl + F',
      'Escape',
    ]) {
      expect(find.text(shortcut), findsOneWidget);
    }

    expect(
      find.textContaining('استمرار الضغط على Enter أو Tab'),
      findsOneWidget,
    );
    expect(
      find.textContaining('السهمان أعلى وأسفل داخل القوائم فقط'),
      findsOneWidget,
    );
  });
}
