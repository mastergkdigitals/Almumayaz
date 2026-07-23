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
  });

  testWidgets('switches between normal and compact desktop layouts',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const AlmumayazApp());
    expect(find.text('إدارة أعمالك بثقة، حتى بدون إنترنت'), findsOneWidget);

    tester.view.physicalSize = const Size(1000, 720);
    await tester.pump();

    expect(find.text('إدارة أعمالك بثقة، حتى بدون إنترنت'), findsNothing);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
