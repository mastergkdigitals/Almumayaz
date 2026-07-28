import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('restores Settings to its empty tinted screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password',
    );
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('dashboardCard_settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('settingsScreen')), findsOneWidget);
    expect(
      find.byKey(const Key('settingsTintBackground')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableTemplate')),
      findsNothing,
    );

    final expectedTint = Color.alphaBlend(
      AppModuleColors.settings.withAlpha(12),
      AppColors.surface,
    );
    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('settingsScreen')),
    );
    expect(shell.subtitle, isNull);
    expect(shell.backgroundColor, expectedTint);

    final tintBackground = tester.widget<ColoredBox>(
      find.byKey(const Key('settingsTintBackground')),
    );
    expect(tintBackground.color, expectedTint);
    expect(tintBackground.child, isNull);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settingsScreen')), findsNothing);
    expect(
      find.byKey(const Key('dashboardCard_settings')),
      findsOneWidget,
    );
  });
}
