import 'package:erp/app/app.dart';
import 'package:erp/features/parties/presentation/parties_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters and navigates the temporary parties list', () {
    final controller = PartiesController();
    addTearDown(controller.dispose);

    expect(controller.state.parties, hasLength(10));

    controller.search('مجهز ال');
    expect(controller.visibleParties, hasLength(2));

    controller.first();
    expect(controller.selectedParty?.name, 'مجهز الرافدين');

    controller.next();
    expect(controller.selectedParty?.name, 'مجهز الفرات');

    controller.last();
    expect(controller.selectedParty?.name, 'مجهز الفرات');
  });

  testWidgets('opens the parties screen with the approved shared controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);

    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('partiesScreen')), findsOneWidget);
    expect(find.text('الأطراف'), findsWidgets);
    expect(find.byKey(const Key('partyForm')), findsOneWidget);
    expect(find.byKey(const Key('partiesActionBar')), findsOneWidget);
    expect(find.byKey(const Key('partiesTable')), findsOneWidget);
    expect(find.byKey(const Key('appScreenBackButton')), findsOneWidget);
    expect(find.text('نوع الطرف مخصص للتقارير فقط'), findsOneWidget);
    expect(find.text('شركة النخيل للتجارة'), findsOneWidget);

    await tester.tap(find.byKey(const Key('partyRow_party-003')));
    await tester.pump();

    final nameInput = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('partyNameField')),
        matching: find.byType(EditableText),
      ),
    );
    expect(nameInput.controller.text, 'مجهز الرافدين');

    await tester.enterText(
      find.byKey(const Key('partiesSearchField')),
      'أسواق دجلة',
    );
    await tester.pump();

    expect(find.text('أسواق دجلة'), findsOneWidget);
    expect(find.text('أحمد كريم'), findsNothing);
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
}
