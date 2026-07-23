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
  });

  testWidgets('opens dashboard with non-empty credentials', (tester) async {
    await tester.pumpWidget(const AlmumayazApp());

    await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('لوحة التحكم'), findsOneWidget);
    expect(find.text('المبيعات'), findsOneWidget);
    expect(find.text('المشتريات'), findsOneWidget);
    expect(find.text('الصندوق'), findsOneWidget);
    expect(find.text('الأطراف'), findsOneWidget);
    expect(find.text('اسم الشركة'), findsOneWidget);
    expect(find.text('المخازن'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('حول'), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_about')), findsOneWidget);
  });

  testWidgets('uses normal desktop layout at 1440 width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());

    expect(find.text('إدارة أعمالك بثقة، حتى بدون إنترنت'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('uses compact desktop layout below 1280 width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());

    expect(find.text('إدارة أعمالك بثقة، حتى بدون إنترنت'), findsNothing);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
