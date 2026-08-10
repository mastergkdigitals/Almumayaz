import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/design_system/presentation/design_system_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpDesignSystemGallery(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: DesignSystemGalleryScreen(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pump();
}
