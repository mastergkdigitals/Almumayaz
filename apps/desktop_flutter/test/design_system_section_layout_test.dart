import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared section layouts preserve selection behavior', (
    tester,
  ) async {
    String? changedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: AppSectionPanel(
              title: 'قسم مشترك',
              icon: Icons.settings_rounded,
              accentColor: AppModuleColors.settings,
              child: AppResponsiveGrid(
                children: [
                  AppSelectionTabs<String>(
                    items: const [
                      (
                        value: 'first',
                        label: 'الأول',
                        icon: Icons.looks_one_rounded,
                      ),
                      (
                        value: 'second',
                        label: 'الثاني',
                        icon: Icons.looks_two_rounded,
                      ),
                    ],
                    selected: 'first',
                    onChanged: (value) => changedValue = value,
                    keyPrefix: 'sharedTab_',
                    accentColor: AppModuleColors.settings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('قسم مشترك'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sharedTab_first')));
    expect(changedValue, isNull);
    await tester.tap(find.byKey(const Key('sharedTab_second')));
    expect(changedValue, 'second');
  });
}
