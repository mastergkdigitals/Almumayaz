import 'package:flutter/widgets.dart';

enum AppEdition { internal, customer }

enum AppModuleId {
  purchases,
  sales,
  cashbox,
  parties,
  company,
  warehouses,
  reports,
  settings,
  about,
}

class AppConfiguration {
  const AppConfiguration._({
    required this.edition,
    required this.showDesignSystem,
    required this.enabledModules,
    this.applicationTitle = 'المميز ERP',
    this.companyName = 'اسم الشركة + الشعار',
    this.companyLogoAsset,
  });

  factory AppConfiguration.fromEnvironment() {
    const editionValue = String.fromEnvironment(
      'APP_EDITION',
      defaultValue: 'internal',
    );
    const designSystemValue = String.fromEnvironment(
      'SHOW_DESIGN_SYSTEM',
      defaultValue: '',
    );
    const modulesValue = String.fromEnvironment(
      'ENABLED_MODULES',
      defaultValue: '',
    );
    const applicationTitle = String.fromEnvironment(
      'APP_TITLE',
      defaultValue: 'المميز ERP',
    );
    const companyName = String.fromEnvironment(
      'COMPANY_NAME',
      defaultValue: 'اسم الشركة + الشعار',
    );
    const companyLogoAsset = String.fromEnvironment(
      'COMPANY_LOGO_ASSET',
      defaultValue: '',
    );

    final edition = editionValue.trim().toLowerCase() == 'customer'
        ? AppEdition.customer
        : AppEdition.internal;
    final designSystemOverride = designSystemValue.trim().toLowerCase();
    final internalDesignSystemRequested = designSystemOverride.isEmpty
        ? true
        : designSystemOverride == 'true';
    // The Design System is a development tool. A customer build must never be
    // able to expose it, even when an incorrect dart-define requests it.
    final showDesignSystem =
        edition == AppEdition.internal && internalDesignSystemRequested;
    final enabledModules = _parseModules(modulesValue);

    return AppConfiguration._(
      edition: edition,
      showDesignSystem: showDesignSystem,
      enabledModules: enabledModules,
      applicationTitle: applicationTitle,
      companyName: companyName,
      companyLogoAsset:
          companyLogoAsset.trim().isEmpty ? null : companyLogoAsset.trim(),
    );
  }

  factory AppConfiguration.internal() {
    return const AppConfiguration._(
      edition: AppEdition.internal,
      showDesignSystem: true,
      enabledModules: {
        AppModuleId.purchases,
        AppModuleId.sales,
        AppModuleId.cashbox,
        AppModuleId.parties,
        AppModuleId.company,
        AppModuleId.warehouses,
        AppModuleId.reports,
        AppModuleId.settings,
        AppModuleId.about,
      },
    );
  }

  factory AppConfiguration.customer({
    String companyName = 'اسم الشركة + الشعار',
    String? companyLogoAsset,
    Set<AppModuleId>? enabledModules,
  }) {
    return AppConfiguration._(
      edition: AppEdition.customer,
      showDesignSystem: false,
      enabledModules: enabledModules ?? AppModuleId.values.toSet(),
      companyName: companyName,
      companyLogoAsset: companyLogoAsset,
    );
  }

  final AppEdition edition;
  final bool showDesignSystem;
  final Set<AppModuleId> enabledModules;
  final String applicationTitle;
  final String companyName;
  final String? companyLogoAsset;

  bool isModuleEnabled(AppModuleId module) {
    return enabledModules.contains(module);
  }

  bool isModuleKeyEnabled(String key) {
    for (final module in AppModuleId.values) {
      if (module.name == key) return isModuleEnabled(module);
    }
    return false;
  }

  static Set<AppModuleId> _parseModules(String value) {
    final requested = value
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (requested.isEmpty) return AppModuleId.values.toSet();

    return {
      for (final module in AppModuleId.values)
        if (requested.contains(module.name)) module,
    };
  }
}

class AppConfigurationScope extends InheritedWidget {
  const AppConfigurationScope({
    required this.configuration,
    required super.child,
    super.key,
  });

  final AppConfiguration configuration;

  static AppConfiguration of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppConfigurationScope>();
    assert(scope != null, 'AppConfigurationScope is missing');
    return scope?.configuration ?? AppConfiguration.internal();
  }

  @override
  bool updateShouldNotify(AppConfigurationScope oldWidget) {
    return configuration != oldWidget.configuration;
  }
}
