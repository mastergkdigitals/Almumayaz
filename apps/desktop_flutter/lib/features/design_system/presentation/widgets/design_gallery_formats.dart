import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryFormatsSection extends StatefulWidget {
  const DesignGalleryFormatsSection({super.key});

  @override
  State<DesignGalleryFormatsSection> createState() =>
      _DesignGalleryFormatsSectionState();
}

class _DesignGalleryFormatsSectionState
    extends State<DesignGalleryFormatsSection> {
  DateTime _date = DateTime(2026, 12, 31);

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'التاريخ والوقت وتنسيق الأرقام',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'يعرض التطبيق التاريخ والوقت والأرقام بهذه الصيغ في جميع الشاشات والتقارير.',
            icon: Icons.format_list_numbered_rtl_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _FormatCard(
                key: const Key('designDateFormat'),
                title: 'التاريخ',
                value: AppFormatters.date(DateTime(2026, 12, 31)),
                icon: Icons.calendar_month_rounded,
              ),
              _FormatCard(
                key: const Key('designTimeFormat'),
                title: 'الوقت',
                value: AppFormatters.time(
                  const TimeOfDay(hour: 1, minute: 1),
                ),
                icon: Icons.schedule_rounded,
              ),
              _FormatCard(
                key: const Key('designQuantityFormat'),
                title: 'الكمية',
                value: AppFormatters.quantity(1000000),
                icon: Icons.numbers_rounded,
              ),
              _FormatCard(
                key: const Key('designIqdFormat'),
                title: 'الدينار',
                value: AppFormatters.iqd(1000000),
                icon: Icons.payments_rounded,
              ),
              _FormatCard(
                key: const Key('designUsdFormat'),
                title: 'الدولار',
                value: AppFormatters.usd(100000),
                icon: Icons.attach_money_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppDateField(
                  fieldKey: const Key('designGlobalDatePicker'),
                  label: 'التاريخ',
                  value: _date,
                  onChanged: (value) => setState(() => _date = value),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              const Expanded(
                child: AppTimeField(
                  fieldKey: Key('designGlobalReadOnlyTime'),
                  label: 'الوقت',
                  value: TimeOfDay(hour: 13, minute: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'حقل الوقت يولده النظام دائماً: للقراءة فقط، معطل، ولا يفتح منتقي وقت.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
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
      width: 210,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navigation),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: AppTypography.fieldText,
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
