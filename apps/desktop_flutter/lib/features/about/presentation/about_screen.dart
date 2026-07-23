import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import '../../design_system/presentation/design_system_gallery_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      key: const Key('aboutScreen'),
      title: 'حول البرنامج',
      onBack: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 112, showBackground: false),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'المميز للمحاسبة',
                    style: AppTypography.screenTitle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'نظام ERP عربي لإدارة أعمال الشركة ومخازنها ومستنداتها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppStatusBadge(
                        label: 'Windows',
                        tone: AppStatusTone.info,
                      ),
                      AppStatusBadge(
                        label: 'يعمل بدون إنترنت',
                        tone: AppStatusTone.success,
                      ),
                      AppStatusBadge(
                        label: 'دينار ودولار',
                        tone: AppStatusTone.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    key: const Key('openDesignSystemGallery'),
                    label: 'دليل نظام التصميم',
                    icon: Icons.design_services_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DesignSystemGalleryScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'أداة داخلية لمراجعة عناصر الواجهة أثناء التطوير',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
