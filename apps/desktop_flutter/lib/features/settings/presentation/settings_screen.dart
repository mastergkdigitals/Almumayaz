import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tint = Color.alphaBlend(
      AppModuleColors.settings.withAlpha(12),
      AppColors.surface,
    );

    return AppScreenShell(
      key: const Key('settingsScreen'),
      title: 'الإعدادات',
      backgroundColor: tint,
      onBack: () => Navigator.of(context).pop(),
      body: ColoredBox(
        key: const Key('settingsTintBackground'),
        color: tint,
      ),
    );
  }
}
