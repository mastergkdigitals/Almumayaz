import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

const _options = <String>['الرئيسي', 'الكرادة', 'المنصور'];

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
  final _values = List<String>.filled(8, _options.first);

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
            child: AppTextField(
              controller: controller,
              label: 'المخزن',
              icon: Icons.warehouse_outlined,
              accentColor: AppModuleColors.settings,
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
    final decoration = _decorationFor(design);

    return SizedBox(
      height: AppControlHeights.large,
      child: DropdownButtonFormField<String>(
        key: Key('settingsDropdownDesign$design'),
        initialValue: value,
        isExpanded: true,
        icon: Icon(
          design == 6
              ? Icons.expand_circle_down_outlined
              : Icons.keyboard_arrow_down_rounded,
          color: design == 5
              ? AppColors.onStrong
              : AppModuleColors.settings,
        ),
        dropdownColor: AppColors.surface,
        borderRadius: BorderRadius.circular(
          design == 5 ? AppRadii.xl : AppRadii.md,
        ),
        style: AppTypography.fieldText.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: decoration,
        selectedItemBuilder: (context) => _options
            .map(
              (option) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  option,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.fieldText.copyWith(
                    color: design == 5
                        ? AppColors.onStrong
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(growable: false),
        items: _options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _decorationFor(int design) {
    const accent = AppModuleColors.settings;
    const border = AppColors.border;
    final standard = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: const BorderSide(color: border),
    );
    final focused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: const BorderSide(color: accent, width: 1.6),
    );

    switch (design) {
      case 1:
        return InputDecoration(
          labelText: 'المخزن',
          prefixIcon: const Icon(Icons.warehouse_outlined, color: accent),
          enabledBorder: standard,
          focusedBorder: focused,
        );
      case 2:
        return InputDecoration(
          labelText: 'المخزن',
          filled: true,
          fillColor: AppColors.neutralSurface,
          prefixIcon: const Icon(Icons.warehouse_rounded, color: accent),
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
        return const InputDecoration(
          labelText: 'المخزن',
          prefixIcon: Icon(Icons.warehouse_outlined, color: accent),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: border, width: 1.4),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: accent, width: 2),
          ),
        );
      case 4:
        return InputDecoration(
          labelText: 'المخزن',
          filled: true,
          fillColor: AppColors.surface,
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
        return InputDecoration(
          labelText: 'المخزن',
          labelStyle: const TextStyle(color: AppColors.onStrong),
          floatingLabelStyle: const TextStyle(color: AppColors.onStrong),
          filled: true,
          fillColor: accent,
          prefixIcon:
              const Icon(Icons.warehouse_outlined, color: AppColors.onStrong),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: accent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: AppColors.textPrimary, width: 2),
          ),
        );
      case 6:
        return InputDecoration(
          labelText: 'المخزن',
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          prefixIcon: const Icon(Icons.inventory_2_outlined, color: accent),
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
        return InputDecoration(
          labelText: 'المخزن',
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          prefixIcon: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(Icons.warehouse_outlined, color: accent),
          ),
          enabledBorder: standard,
          focusedBorder: focused,
        );
      default:
        return InputDecoration(
          labelText: 'المخزن',
          prefixIcon: const Icon(Icons.warehouse_outlined, color: accent),
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
          focusedBorder: focused,
        );
    }
  }
}
