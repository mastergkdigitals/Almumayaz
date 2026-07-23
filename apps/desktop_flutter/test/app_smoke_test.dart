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

    final currencyDropdown =
        find.byKey(const Key('designCurrencyDropdown'));
    await tester.ensureVisible(currencyDropdown);
    await tester.pump();
    await tester.tap(currencyDropdown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('دولار'), findsOneWidget);
  });
}
