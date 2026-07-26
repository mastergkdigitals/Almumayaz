import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens an empty purchase screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_purchases')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('purchaseScreen')), findsOneWidget);
    expect(find.byKey(const Key('purchaseEmptyBody')), findsOneWidget);
    expect(find.byKey(const Key('appScreenBackButton')), findsOneWidget);

    for (final removedKey in const [
      'purchaseHeaderPanel',
      'purchaseItemsTable',
      'purchaseTotalsPanel',
      'purchaseActionBar',
      'purchaseSearchButton',
    ]) {
      expect(find.byKey(Key(removedKey)), findsNothing);
    }

    final backButton = tester.widget<AppHeaderIconButton>(
      find.byKey(const Key('appScreenBackButton')),
    );
    expect(backButton.onPressed, isNotNull);
    backButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('purchaseScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsOneWidget);
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
