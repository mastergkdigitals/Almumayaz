import 'package:erp/app/app.dart';
import 'package:erp/core/design/components/app_screen_shell.dart';
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

  testWidgets('moves to password and toggles rounded visibility icons',
      (tester) async {
    await tester.pumpWidget(const AlmumayazApp());
    await tester.pump();

    final username = find.byKey(const Key('usernameField'));
    final password = find.byKey(const Key('passwordField'));
    final visibilityButton =
        find.byKey(const Key('passwordVisibilityButton'));

    await tester.enterText(username, 'admin');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    EditableText passwordInput() => tester.widget<EditableText>(
          find.descendant(
            of: password,
            matching: find.byType(EditableText),
          ),
        );
    Icon visibilityIcon() => tester.widget<Icon>(
          find.descendant(
            of: visibilityButton,
            matching: find.byType(Icon),
          ),
        );

    expect(passwordInput().focusNode.hasFocus, isTrue);
    expect(passwordInput().obscureText, isTrue);
    expect(visibilityIcon().icon, Icons.visibility_off_rounded);
    expect(tester.widget<IconButton>(visibilityButton).tooltip, isNull);

    await tester.tap(visibilityButton);
    await tester.pump();

    expect(passwordInput().obscureText, isFalse);
    expect(visibilityIcon().icon, Icons.visibility_rounded);
  });

  testWidgets('opens dashboard with approved nine cards', (tester) async {
    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);

    expect(find.text('لوحة التحكم'), findsNothing);
    expect(find.text('اختر القسم الذي تريد العمل عليه'), findsNothing);
    expect(find.text('المبيعات'), findsOneWidget);
    expect(find.text('المشتريات'), findsOneWidget);
    expect(find.text('الصندوق'), findsOneWidget);
    expect(find.text('الأطراف'), findsOneWidget);
    expect(find.text('اسم الشركة + الشعار'), findsOneWidget);
    expect(find.text('المخازن'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('حول'), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_about')), findsOneWidget);
    expect(find.byKey(const Key('appScreenBackButton')), findsNothing);

    final purchasesInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('dashboardCard_purchases')),
        matching: find.byType(InkWell),
      ),
    );
    expect(
      purchasesInkWell.overlayColor?.resolve(
        <WidgetState>{WidgetState.pressed},
      ),
      Colors.transparent,
    );
    expect(purchasesInkWell.splashFactory, NoSplash.splashFactory);
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
    await _login(tester);

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

  testWidgets('opens About before the developer design guide', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);

    await tester.tap(find.byKey(const Key('dashboardCard_about')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('aboutScreen')), findsOneWidget);
    expect(find.text('حول البرنامج'), findsOneWidget);
    expect(find.text('دليل نظام التصميم'), findsOneWidget);
    expect(find.byKey(const Key('designSystemGallery')), findsNothing);
    expect(find.byKey(const Key('appScreenBackButton')), findsOneWidget);
    final aboutScreen = find.byKey(const Key('aboutScreen'));
    final aboutHeader = find.descendant(
      of: aboutScreen,
      matching: find.byType(AppScreenHeader),
    );
    final aboutTitle = find.descendant(
      of: aboutHeader,
      matching: find.text('حول البرنامج'),
    );
    expect(
      tester.getCenter(aboutTitle).dx,
      closeTo(tester.getCenter(aboutHeader).dx, 0.1),
    );

    await tester.tap(find.byKey(const Key('openDesignSystemGallery')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final gallery = find.byKey(const Key('designSystemGallery'));
    final galleryHeader = find.descendant(
      of: gallery,
      matching: find.byType(AppScreenHeader),
    );
    final galleryTitle = find.descendant(
      of: galleryHeader,
      matching: find.text('دليل نظام التصميم'),
    );
    final gallerySubtitle = find.descendant(
      of: galleryHeader,
      matching: find.text('مرجع موحد لعناصر الواجهة وحالاتها'),
    );

    expect(gallery, findsOneWidget);
    expect(
      tester.getCenter(galleryTitle).dx,
      closeTo(tester.getCenter(galleryHeader).dx, 0.1),
    );
    expect(
      tester.getCenter(gallerySubtitle).dx,
      closeTo(tester.getCenter(galleryHeader).dx, 0.1),
    );
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
}
