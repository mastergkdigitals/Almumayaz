import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryFoundationsSection extends StatelessWidget {
  const DesignGalleryFoundationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      key: const Key('designFoundationsSection'),
      title: 'القياسات وأساسيات الواجهة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'مرجع بصري موحد للاستجابة والارتفاعات والزوايا والمسافات والخطوط.',
            icon: Icons.straighten_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _FoundationTitle('الاستجابة'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _MetricCard(
                key: const Key('designFoundationCanvas'),
                title: 'عرض التصميم الأساسي',
                value: '${AppBreakpoints.designWidth.toInt()} px',
                icon: Icons.desktop_windows_rounded,
              ),
              const _MetricCard(
                key: Key('designFoundationMinimumWindow'),
                title: 'أدنى نافذة مستعادة',
                value: '1280 × 720',
                icon: Icons.aspect_ratio_rounded,
              ),
              const _MetricCard(
                key: Key('designFoundationAspectRatio'),
                title: 'نسبة النافذة المستعادة',
                value: '16:9',
                icon: Icons.fit_screen_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _FoundationTitle('ارتفاعات عناصر التحكم'),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _ControlHeightSample(
                key: Key('designFoundationCompactHeight'),
                label: 'مدمج',
                height: AppControlHeights.compact,
              ),
              _ControlHeightSample(
                key: Key('designFoundationStandardHeight'),
                label: 'قياسي',
                height: AppControlHeights.standard,
              ),
              _ControlHeightSample(
                key: Key('designFoundationRegularButtonHeight'),
                label: 'زر عادي وتنقل',
                height: AppRegularButton.defaultHeight,
              ),
              _ControlHeightSample(
                key: Key('designFoundationLargeHeight'),
                label: 'كبير',
                height: AppControlHeights.large,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _FoundationTitle('الزوايا'),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _RadiusSample(label: 'صغير', radius: AppRadii.sm),
              _RadiusSample(label: 'متوسط', radius: AppRadii.md),
              _RadiusSample(label: 'كبير', radius: AppRadii.lg),
              _RadiusSample(label: 'كبير جداً', radius: AppRadii.xl),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _FoundationTitle('المسافات'),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            key: Key('designFoundationSpacing'),
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _SpacingSample(label: 'XS', value: AppSpacing.xs),
              _SpacingSample(label: 'SM', value: AppSpacing.sm),
              _SpacingSample(label: 'MD', value: AppSpacing.md),
              _SpacingSample(label: 'LG', value: AppSpacing.lg),
              _SpacingSample(label: 'XL', value: AppSpacing.xl),
              _SpacingSample(label: 'XXL', value: AppSpacing.xxl),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _FoundationTitle('الخطوط'),
          const SizedBox(height: AppSpacing.md),
          const _TypographyPreview(
            key: Key('designFoundationTypography'),
          ),
        ],
      ),
    );
  }
}

class _FoundationTitle extends StatelessWidget {
  const _FoundationTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTypography.sectionTitle);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.blue.withAlpha(44)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: AppIconSizes.lg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlHeightSample extends StatelessWidget {
  const _ControlHeightSample({
    required this.label,
    required this.height,
    super.key,
  });

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.neutralSurface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppColors.controlHoverBorder),
            ),
            child: Text(
              '${height.toInt()} px',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadiusSample extends StatelessWidget {
  const _RadiusSample({
    required this.label,
    required this.radius,
  });

  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.controlHoverBorder),
      ),
      child: Text(
        '$label  •  ${radius.toInt()} px',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SpacingSample extends StatelessWidget {
  const _SpacingSample({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: value * 2,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$label • ${value.toInt()}',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TypographyPreview extends StatelessWidget {
  const _TypographyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('عنوان الشاشة', style: AppTypography.screenTitle),
          const SizedBox(height: AppSpacing.md),
          const Text('عنوان القسم', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          const Text('نص الحقل', style: AppTypography.fieldText),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'نص الزر العادي والتنقل',
            style: AppRegularButton.defaultTextStyle,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('عنوان الجدول', style: AppTypography.tableHeader),
          const SizedBox(height: AppSpacing.sm),
          const Text('نص خلية الجدول', style: AppTypography.tableCell),
        ],
      ),
    );
  }
}
