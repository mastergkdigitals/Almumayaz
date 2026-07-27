import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps only the purchase tint background', (tester) async {
    await _openPurchaseScreen(tester);

    expect(find.byKey(const Key('purchaseScreen')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTintBackground')), findsOneWidget);
    expect(find.byKey(const Key('purchaseItemsTable')), findsNothing);
    expect(find.byKey(const Key('purchaseTableFit')), findsNothing);
    expect(find.byKey(const Key('purchaseTableSurface')), findsNothing);
    expect(find.byKey(const Key('purchaseCode-r1')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('purchaseScreen')),
        matching: find.text('المشتريات'),
      ),
      findsOneWidget,
    );

    for (final removedKey in const [
      'purchaseHeaderPanel',
      'purchaseTablePanel',
      'purchaseTotalsPanel',
      'purchaseActionBar',
    ]) {
      expect(find.byKey(Key(removedKey)), findsNothing);
    }

    final expectedTint = Color.alphaBlend(
      AppModuleColors.purchases.withAlpha(12),
      AppColors.surface,
    );
    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('purchaseScreen')),
    );
    expect(shell.subtitle, isNull);
    expect(shell.backgroundColor, expectedTint);

    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byKey(const Key('purchaseScreen')),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, expectedTint);
    final tintBackground = tester.widget<ColoredBox>(
      find.byKey(const Key('purchaseTintBackground')),
    );
    expect(tintBackground.color, expectedTint);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('purchaseScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsOneWidget);
  });
}

Future<void> _openPurchaseScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const Key('dashboardCard_purchases')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
