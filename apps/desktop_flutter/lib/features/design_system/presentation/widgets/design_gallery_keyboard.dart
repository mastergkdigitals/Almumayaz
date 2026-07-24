import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryKeyboardSection extends StatelessWidget {
  const DesignGalleryKeyboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const DesignGallerySection(
      title: 'معايير لوحة المفاتيح',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _KeyboardRule(
                shortcut: 'Enter',
                description: 'الانتقال للحقل التالي والتوقف عند آخر حقل',
                icon: Icons.keyboard_return_rounded,
              ),
              _KeyboardRule(
                shortcut: 'Tab',
                description: 'الانتقال للحقل التالي داخل النموذج',
                icon: Icons.keyboard_tab_rounded,
              ),
              _KeyboardRule(
                shortcut: 'Shift + Tab',
                description: 'الرجوع إلى الحقل السابق',
                icon: Icons.keyboard_tab_rounded,
              ),
              _KeyboardRule(
                shortcut: 'Ctrl + S',
                description: 'حفظ السجل الجديد أو تحديث السجل المعدل',
                icon: Icons.save_rounded,
              ),
              _KeyboardRule(
                shortcut: 'Ctrl + F',
                description: 'نقل التركيز إلى حقل البحث',
                icon: Icons.search_rounded,
              ),
              _KeyboardRule(
                shortcut: 'Escape',
                description: 'إغلاق القائمة ثم النافذة ثم الرجوع بأمان',
                icon: Icons.close_rounded,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          AppInfoBanner(
            message:
                'استمرار الضغط على Enter أو Tab ينفذ حركة واحدة فقط. الأسهم لا تنقل التركيز، ويعمل السهمان أعلى وأسفل داخل القوائم فقط.',
            icon: Icons.keyboard_rounded,
          ),
        ],
      ),
    );
  }
}

class _KeyboardRule extends StatelessWidget {
  const _KeyboardRule({
    required this.shortcut,
    required this.description,
    required this.icon,
  });

  final String shortcut;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navigation),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortcut,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.navigation,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
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
