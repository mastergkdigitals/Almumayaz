import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

const _options = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controllers = List.generate(
    8,
    (_) => TextEditingController(text: 'الرئيسي'),
  );
  final _values = List<String>.filled(8, _options.first.value);

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      title: 'اختبار تصاميم القائمة المنسدلة',
      subtitle: 'الحقل العادي يميناً والقائمة المنسدلة يساراً',
      onBack: () => Navigator.of(context).pop(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.xl),
          itemCount: 8,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            return _DesignRow(
              number: index + 1,
              controller: _controllers[index],
              value: _values[index],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _values[index] = value);
              },
            );
          },
        ),
      ),
    );
  }
}

class _DesignRow extends StatelessWidget {
  const _DesignRow({
    required this.number,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  final int number;
  final TextEditingController controller;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '$number',
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle.copyWith(
                color: AppModuleColors.settings,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: AppControlHeights.large,
              child: AppTextField(
                controller: controller,
                label: 'المخزن',
                icon: Icons.warehouse_outlined,
                accentColor: AppModuleColors.settings,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: _DropdownCandidate(
              design: number,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownCandidate extends StatelessWidget {
  const _DropdownCandidate({
    required this.design,
    required this.value,
    required this.onChanged,
  });

  final int design;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<String>(
      fieldKey: Key('settingsDropdownDesign$design'),
      label: 'المخزن',
      options: _options,
      value: value,
      onChanged: onChanged,
      icon: _iconFor(design),
      accentColor: AppModuleColors.settings,
      decorationBuilder: (decoration) =>
          _decorationFor(design, decoration),
    );
  }

  IconData _iconFor(int design) {
    return design == 6
        ? Icons.inventory_2_outlined
        : Icons.warehouse_outlined;
  }

  InputDecoration _decorationFor(
    int design,
    InputDecoration decoration,
  ) {
    const accent = AppModuleColors.settings;
    const border = AppColors.border;

    switch (design) {
      case 1:
        return decoration;
      case 2:
        return decoration.copyWith(
          fillColor: AppColors.neutralSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            borderSide: const BorderSide(color: accent, width: 1.6),
          ),
        );
      case 3:
        return decoration.copyWith(
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: border, width: 1.4),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: accent, width: 2),
          ),
        );
      case 4:
        return decoration.copyWith(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: accent, width: 1.6),
          ),
        );
      case 5:
        return decoration.copyWith(
          fillColor: const Color(0xFFE5E7EB),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
        );
      case 6:
        return decoration.copyWith(
          fillColor: const Color(0xFFF3F4F6),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
        );
      case 7:
        return decoration.copyWith(
          fillColor: const Color(0xFFF9FAFB),
          prefixIcon: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(Icons.warehouse_outlined, color: accent),
          ),
        );
      default:
        return decoration.copyWith(
          suffixText: 'اختيار',
          suffixStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: accent, width: 1.4),
          ),
        );
    }
  }
}
