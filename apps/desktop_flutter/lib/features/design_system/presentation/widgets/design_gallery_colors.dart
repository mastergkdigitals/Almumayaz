import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryColorsSection extends StatelessWidget {
  const DesignGalleryColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const DesignGallerySection(
      title: 'الألوان',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          _ColorSample(
            name: 'الأساسي',
            value: '#1D4ED8',
            color: AppColors.primary,
          ),
          _ColorSample(
            name: 'الأزرق الداكن',
            value: '#102A56',
            color: AppColors.primaryDark,
          ),
          _ColorSample(
            name: 'النجاح',
            value: '#0F7A4D',
            color: AppColors.success,
          ),
          _ColorSample(
            name: 'التنبيه',
            value: '#B75C00',
            color: AppColors.warning,
          ),
          _ColorSample(
            name: 'الخطر',
            value: '#B42318',
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _ColorSample extends StatelessWidget {
  const _ColorSample({
    required this.name,
    required this.value,
    required this.color,
  });

  final String name;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 92,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppColors.onStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(color: AppColors.onStrong.withAlpha(179)),
          ),
        ],
      ),
    );
  }
}
