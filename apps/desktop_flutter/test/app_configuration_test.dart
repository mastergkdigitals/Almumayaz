import 'package:erp/core/config/app_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('internal configuration keeps all modules and Design System', () {
    final configuration = AppConfiguration.internal();

    expect(configuration.edition, AppEdition.internal);
    expect(configuration.showDesignSystem, isTrue);
    expect(configuration.enabledModules, containsAll(AppModuleId.values));
  });

  test('customer configuration hides Design System and supports modules', () {
    final configuration = AppConfiguration.customer(
      companyName: 'شركة الاختبار',
      enabledModules: {
        AppModuleId.sales,
        AppModuleId.reports,
        AppModuleId.about,
      },
    );

    expect(configuration.edition, AppEdition.customer);
    expect(configuration.showDesignSystem, isFalse);
    expect(configuration.companyName, 'شركة الاختبار');
    expect(configuration.isModuleEnabled(AppModuleId.sales), isTrue);
    expect(configuration.isModuleEnabled(AppModuleId.purchases), isFalse);
  });

  testWidgets('configuration scope exposes one build profile', (tester) async {
    late AppConfiguration value;

    await tester.pumpWidget(
      AppConfigurationScope(
        configuration: AppConfiguration.customer(),
        child: Builder(
          builder: (context) {
            value = AppConfigurationScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(value.edition, AppEdition.customer);
  });
}
