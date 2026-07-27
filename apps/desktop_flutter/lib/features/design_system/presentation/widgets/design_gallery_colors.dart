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
      _ColorShade('#BBDEFB', Color(0xFFBBDEFB)),
      _ColorShade('#64B5F6', Color(0xFF64B5F6)),
      _ColorShade('#2196F3', Color(0xFF2196F3)),
      _ColorShade('#1976D2', Color(0xFF1976D2)),
      _ColorShade('#0D47A1', Color(0xFF0D47A1)),
    ],
  ),
  _ColorFamily(
    name: 'الأخضر',
    shades: [
      _ColorShade('#C8E6C9', Color(0xFFC8E6C9)),
      _ColorShade('#81C784', Color(0xFF81C784)),
      _ColorShade('#4CAF50', Color(0xFF4CAF50)),
      _ColorShade('#388E3C', Color(0xFF388E3C)),
      _ColorShade('#1B5E20', Color(0xFF1B5E20)),
    ],
  ),
  _ColorFamily(
    name: 'الأصفر',
    shades: [
      _ColorShade('#FFF9C4', Color(0xFFFFF9C4)),
      _ColorShade('#FFF176', Color(0xFFFFF176)),
      _ColorShade('#FFEB3B', Color(0xFFFFEB3B)),
      _ColorShade('#FBC02D', Color(0xFFFBC02D)),
      _ColorShade('#F57F17', Color(0xFFF57F17)),
    ],
  ),
  _ColorFamily(
    name: 'البرتقالي',
    shades: [
      _ColorShade('#FFE0B2', Color(0xFFFFE0B2)),
      _ColorShade('#FFB74D', Color(0xFFFFB74D)),
      _ColorShade('#FF9800', Color(0xFFFF9800)),
      _ColorShade('#F57C00', Color(0xFFF57C00)),
      _ColorShade('#E65100', Color(0xFFE65100)),
    ],
  ),
  _ColorFamily(
    name: 'الرمادي',
    shades: [
      _ColorShade('#F5F5F5', Color(0xFFF5F5F5)),
      _ColorShade('#E0E0E0', Color(0xFFE0E0E0)),
      _ColorShade('#9E9E9E', Color(0xFF9E9E9E)),
      _ColorShade('#616161', Color(0xFF616161)),
      _ColorShade('#212121', Color(0xFF212121)),
    ],
  ),
  _ColorFamily(
    name: 'الأحمر',
    shades: [
      _ColorShade('#FFCDD2', Color(0xFFFFCDD2)),
      _ColorShade('#E57373', Color(0xFFE57373)),
      _ColorShade('#F44336', Color(0xFFF44336)),
      _ColorShade('#D32F2F', Color(0xFFD32F2F)),
      _ColorShade('#B71C1C', Color(0xFFB71C1C)),
    ],
  ),
  _ColorFamily(
    name: 'البني',
    shades: [
      _ColorShade('#D7CCC8', Color(0xFFD7CCC8)),
      _ColorShade('#A1887F', Color(0xFFA1887F)),
      _ColorShade('#795548', Color(0xFF795548)),
      _ColorShade('#5D4037', Color(0xFF5D4037)),
      _ColorShade('#3E2723', Color(0xFF3E2723)),
    ],
  ),
  _ColorFamily(
    name: 'الأرجواني',
    shades: [
      _ColorShade('#E1BEE7', Color(0xFFE1BEE7)),
      _ColorShade('#BA68C8', Color(0xFFBA68C8)),
      _ColorShade('#9C27B0', Color(0xFF9C27B0)),
      _ColorShade('#7B1FA2', Color(0xFF7B1FA2)),
      _ColorShade('#4A148C', Color(0xFF4A148C)),
    ],
  ),
  _ColorFamily(
    name: 'البنفسجي',
    shades: [
      _ColorShade('#D1C4E9', Color(0xFFD1C4E9)),
      _ColorShade('#9575CD', Color(0xFF9575CD)),
      _ColorShade('#673AB7', Color(0xFF673AB7)),
      _ColorShade('#512DA8', Color(0xFF512DA8)),
      _ColorShade('#311B92', Color(0xFF311B92)),
    ],
  ),
  _ColorFamily(
    name: 'السماوي',
    shades: [
      _ColorShade('#B2EBF2', Color(0xFFB2EBF2)),
      _ColorShade('#4DD0E1', Color(0xFF4DD0E1)),
      _ColorShade('#00BCD4', Color(0xFF00BCD4)),
      _ColorShade('#0097A7', Color(0xFF0097A7)),
      _ColorShade('#006064', Color(0xFF006064)),
    ],
  ),
  _ColorFamily(
    name: 'الماجنتا',
    shades: [
      _ColorShade('#F8BBD0', Color(0xFFF8BBD0)),
      _ColorShade('#F06292', Color(0xFFF06292)),
      _ColorShade('#E91E63', Color(0xFFE91E63)),
      _ColorShade('#C2185B', Color(0xFFC2185B)),
      _ColorShade('#880E4F', Color(0xFF880E4F)),
    ],
  ),
  _ColorFamily(
    name: 'الفيروزي',
    shades: [
      _ColorShade('#B2DFDB', Color(0xFFB2DFDB)),
      _ColorShade('#4DB6AC', Color(0xFF4DB6AC)),
      _ColorShade('#009688', Color(0xFF009688)),
      _ColorShade('#00796B', Color(0xFF00796B)),
      _ColorShade('#004D40', Color(0xFF004D40)),
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
              _ColorSample(
                name: 'الأحمر (القديم)',
                value: '#DC2626',
                color: AppColors.legacyRed,
              ),
              _ColorSample(
                name: 'الأزرق (القديم)',
                value: '#2563EB',
                color: AppColors.legacyBlue,
              ),
              _ColorSample(
                name: 'الرمادي (القديم)',
                value: '#64748B',
                color: AppColors.legacyGrey,
              ),
              _ColorSample(
                name: 'البرتقالي (القديم)',
                value: '#F97316',
                color: AppColors.legacyOrange,
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
            fontSize: 18,
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
      height: 92,
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
