import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );

    return AppScreenShell(
      key: const Key('salesScreen'),
      title: 'المبيعات',
      backgroundColor: tint,
      onBack: () => Navigator.of(context).pop(),
      body: ColoredBox(
        key: const Key('salesTintBackground'),
        color: tint,
      ),
    );
  }
}
