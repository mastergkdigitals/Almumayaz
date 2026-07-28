import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryTablesSection extends StatelessWidget {
  const DesignGalleryTablesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'قالب جداول التطبيق',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'جدول المبيعات',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(
            height: 360,
            child: AppSalesInvoiceTableTemplate(
              key: Key('designSalesInvoiceTable'),
            ),
          ),
        ],
      ),
    );
  }
}
