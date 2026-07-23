import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import 'widgets/design_gallery_actions.dart';
import 'widgets/design_gallery_colors.dart';
import 'widgets/design_gallery_feedback.dart';
import 'widgets/design_gallery_fields.dart';

class DesignSystemGalleryScreen extends StatelessWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      key: const Key('designSystemGallery'),
      title: 'دليل نظام التصميم',
      subtitle: 'مرجع موحد لعناصر الواجهة وحالاتها',
      onBack: () => Navigator.of(context).pop(),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesignGalleryColorsSection(),
            SizedBox(height: AppSpacing.lg),
            DesignGalleryActionsGroup(),
            SizedBox(height: AppSpacing.lg),
            DesignGalleryFieldsGroup(),
            SizedBox(height: AppSpacing.lg),
            DesignGalleryFeedbackGroup(),
            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
