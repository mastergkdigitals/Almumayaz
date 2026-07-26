import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      key: const Key('purchaseScreen'),
      title: 'المشتريات',
      onBack: () => Navigator.of(context).pop(),
      body: const SizedBox.expand(
        key: Key('purchaseEmptyBody'),
      ),
    );
  }
}
