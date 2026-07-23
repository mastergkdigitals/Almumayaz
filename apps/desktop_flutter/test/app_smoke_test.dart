import 'package:erp/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Arabic login screen', (tester) async {
    await tester.pumpWidget(const AlmumayazApp());

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('اسم المستخدم'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
    expect(find.text('إدارة أعمالك بثقة، حتى بدون إنترنت'), findsOneWidget);
  });

  testWidgets('opens dashboard with approved nine cards', (tester) async {
    await tester.pumpWidget(const AlmumayazApp());

    await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('لوحة التحكم'), findsNothing);
    expect(find.text('اختر القسم الذي تريد العمل عليه'), findsNothing);
    expect(find.text('المبيعات'), findsOneWidget);
    expect(find.text('المشتريات'), findsOneWidget);
    expect(find.text('الصندوق'), findsOneWidget);
    expect(find.text('الأطراف'), findsOneWidget);
    expect(find.text('اسم الشركة + الشعار'), findsOneWidget);
    expect(find.text('المميز للمحاسبة'), findsOneWidget);
    expect(find.text('المخازن'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('حول'), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_about')), findsOneWidget);
  });

  testWidgets('keeps full login layout at 1440 width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());

    expect(find.text('إدارة أعمالك بثقة، حتى بدون إنترنت'), findsOneWidget);
    expect(find.text('المميز للمحاسبة'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);

    final brandCenter =
        tester.getCenter(find.byKey(const Key('loginBrandSection')));
    final formCenter =
        tester.getCenter(find.byKey(const Key('loginFormSection')));

    expect(formCenter.dx, greaterThan(brandCenter.dx));
  });

  testWidgets('keeps full login layout below 1280 width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());

    expect(find.text('إدارة أعمالك بثقة، حتى بدون إنترنت'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('keeps dashboard first row in three columns when narrow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    final purchasesY = tester
        .getTopLeft(find.byKey(const Key('dashboardCard_purchases')))
        .dy;
    final salesY =
        tester.getTopLeft(find.byKey(const Key('dashboardCard_sales'))).dy;
    final cashboxY =
        tester.getTopLeft(find.byKey(const Key('dashboardCard_cashbox'))).dy;

    expect(salesY, closeTo(purchasesY, 0.1));
    expect(cashboxY, closeTo(purchasesY, 0.1));
  });

  testWidgets('opens the design system gallery from about', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboardCard_about')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('designSystemGallery')), findsOneWidget);
    expect(find.text('دليل نظام التصميم'), findsOneWidget);
    expect(find.text('الأزرار'), findsOneWidget);
    expect(find.text('حقول الإدخال'), findsOneWidget);
    expect(find.text('الجدول والترقيم'), findsOneWidget);

    final primaryButton = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const Key('designPrimaryButton')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(
      primaryButton.style?.mouseCursor?.resolve(<WidgetState>{}),
      SystemMouseCursors.click,
    );

    expect(find.text('الأول'), findsOneWidget);
    expect(find.text('السابق'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(find.text('الأخير'), findsOneWidget);

    final firstPosition = tester.getCenter(
      find.byKey(const Key('designNavigationFirst')),
    );
    final previousPosition = tester.getCenter(
      find.byKey(const Key('designNavigationPrevious')),
    );
    final nextPosition = tester.getCenter(
      find.byKey(const Key('designNavigationNext')),
    );
    final lastPosition = tester.getCenter(
      find.byKey(const Key('designNavigationLast')),
    );

    for (final key in const [
      Key('designNavigationFirst'),
      Key('designNavigationPrevious'),
      Key('designNavigationNext'),
      Key('designNavigationLast'),
    ]) {
      expect(tester.getSize(find.byKey(key)).width, 116);
    }

    expect(firstPosition.dx, greaterThan(previousPosition.dx));
    expect(previousPosition.dx, greaterThan(nextPosition.dx));
    expect(nextPosition.dx, greaterThan(lastPosition.dx));
    expect(previousPosition.dy, closeTo(firstPosition.dy, 0.1));
    expect(nextPosition.dy, closeTo(firstPosition.dy, 0.1));
    expect(lastPosition.dy, closeTo(firstPosition.dy, 0.1));

    final previousButton =
        find.byKey(const Key('designNavigationPrevious'));
    final nextButton = find.byKey(const Key('designNavigationNext'));
    final lastButton = find.byKey(const Key('designNavigationLast'));

    final previousIcon = find.descendant(
      of: previousButton,
      matching: find.byType(Icon),
    );
    final nextIcon = find.descendant(
      of: nextButton,
      matching: find.byType(Icon),
    );
    final lastIcon = find.descendant(
      of: lastButton,
      matching: find.byType(Icon),
    );

    expect(
      tester.widget<Icon>(previousIcon).icon,
      Icons.chevron_left_rounded,
    );
    expect(
      tester.widget<Icon>(nextIcon).icon,
      Icons.chevron_right_rounded,
    );
    expect(
      tester.getCenter(find.text('التالي')).dx,
      greaterThan(tester.getCenter(nextIcon).dx),
    );
    expect(
      tester.getCenter(find.text('الأخير')).dx,
      greaterThan(tester.getCenter(lastIcon).dx),
    );

    final currencyDropdown =
        find.byKey(const Key('designCurrencyDropdown'));
    await tester.ensureVisible(currencyDropdown);
    await tester.pump();
    await tester.tap(currencyDropdown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('دولار'), findsOneWidget);
    await tester.tap(find.text('دولار'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final searchField = find.byKey(const Key('designSearchField'));
    await Scrollable.ensureVisible(
      tester.element(searchField),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pump();

    expect(
      find.byKey(const Key('designSearchClearButton')),
      findsNothing,
    );

    await tester.enterText(searchField, 'مادة');
    await tester.pump();

    expect(
      find.byKey(const Key('designSearchClearButton')),
      findsOneWidget,
    );

    final clearButton =
        find.byKey(const Key('designSearchClearButton'));
    await Scrollable.ensureVisible(
      tester.element(clearButton),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pump();

    expect(tester.widget<IconButton>(clearButton).onPressed, isNotNull);
    await tester.tap(clearButton);
    await tester.pump();

    final textField = tester.widget<TextFormField>(searchField);
    expect(textField.controller?.text, isEmpty);
    expect(
      find.byKey(const Key('designSearchClearButton')),
      findsNothing,
    );
  });
}
