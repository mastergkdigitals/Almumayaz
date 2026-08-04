import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

const _shadeNames = <String>[
  'فاتح جداً',
  'فاتح',
  'متوسط',
  'داكن',
  'داكن جداً',
];

const _colorFamilies = <_ColorFamily>[
  _ColorFamily(
    name: 'الأزرق',
    shades: [
      _ColorShade('#DBEAFE', Color(0xFFDBEAFE)),
      _ColorShade('#60A5FA', Color(0xFF60A5FA)),
      _ColorShade('#2563EB', AppColors.blue),
      _ColorShade('#1D4ED8', Color(0xFF1D4ED8)),
      _ColorShade('#1E3A8A', Color(0xFF1E3A8A)),
    ],
  ),
  _ColorFamily(
    name: 'الأخضر',
    shades: [
      _ColorShade('#DCFCE7', Color(0xFFDCFCE7)),
      _ColorShade('#4ADE80', Color(0xFF4ADE80)),
      _ColorShade('#16A34A', AppColors.green),
      _ColorShade('#15803D', Color(0xFF15803D)),
      _ColorShade('#14532D', Color(0xFF14532D)),
    ],
  ),
  _ColorFamily(
    name: 'البرتقالي',
    shades: [
      _ColorShade('#FFEDD5', Color(0xFFFFEDD5)),
      _ColorShade('#FDBA74', Color(0xFFFDBA74)),
      _ColorShade('#F97316', AppColors.orange),
      _ColorShade('#EA580C', Color(0xFFEA580C)),
      _ColorShade('#9A3412', Color(0xFF9A3412)),
    ],
  ),
  _ColorFamily(
    name: 'الرمادي',
    shades: [
      _ColorShade('#F1F5F9', Color(0xFFF1F5F9)),
      _ColorShade('#CBD5E1', Color(0xFFCBD5E1)),
      _ColorShade('#64748B', AppColors.grey),
      _ColorShade('#475569', Color(0xFF475569)),
      _ColorShade('#1E293B', Color(0xFF1E293B)),
    ],
  ),
  _ColorFamily(
    name: 'الأحمر',
    shades: [
      _ColorShade('#FEE2E2', Color(0xFFFEE2E2)),
      _ColorShade('#F87171', Color(0xFFF87171)),
      _ColorShade('#DC2626', AppColors.red),
      _ColorShade('#B91C1C', Color(0xFFB91C1C)),
      _ColorShade('#7F1D1D', Color(0xFF7F1D1D)),
    ],
  ),
];

class DesignGalleryColorsSection extends StatelessWidget {
  const DesignGalleryColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'الألوان',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ألوان النظام الحالية',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _ColorSample(
                name: 'الأزرق',
                value: '#2563EB',
                color: AppColors.blue,
              ),
              _ColorSample(
                name: 'الأخضر',
                value: '#16A34A',
                color: AppColors.green,
              ),
              _ColorSample(
                name: 'البرتقالي',
                value: '#F97316',
                color: AppColors.orange,
              ),
              _ColorSample(
                name: 'الرمادي',
                value: '#64748B',
                color: AppColors.grey,
              ),
              _ColorSample(
                name: 'الأحمر',
                value: '#DC2626',
                color: AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'درجات الألوان',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < _colorFamilies.length; index++) ...[
            _ColorFamilyRow(
              key: Key('designColorFamily_$index'),
              family: _colorFamilies[index],
            ),
            if (index < _colorFamilies.length - 1)
              const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _ColorFamilyRow extends StatelessWidget {
  const _ColorFamilyRow({
    required this.family,
    super.key,
  });

  final _ColorFamily family;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          family.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18 * AppDensity.scale,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var index = 0; index < family.shades.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ColorSample(
                  name: _shadeNames[index],
                  value: family.shades[index].value,
                  color: family.shades[index].color,
                  width: double.infinity,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ColorSample extends StatelessWidget {
  const _ColorSample({
    required this.name,
    required this.value,
    required this.color,
    this.width = 180,
  });

  final String name;
  final String value;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? AppColors.onStrong
            : const Color(0xFF111827);

    return Container(
      width: width,
      height: 92 * AppDensity.scale,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: foreground.withAlpha(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(color: foreground.withAlpha(179)),
          ),
        ],
      ),
    );
  }
}

class _ColorFamily {
  const _ColorFamily({
    required this.name,
    required this.shades,
  });

  final String name;
  final List<_ColorShade> shades;
}

class _ColorShade {
  const _ColorShade(this.value, this.color);

  final String value;
  final Color color;
}
