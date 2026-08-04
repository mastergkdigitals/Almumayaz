part of '../settings_sections.dart';

String _backupFrequencyLabel(BackupFrequency frequency) => switch (frequency) {
      BackupFrequency.manual => 'يدوياً',
      BackupFrequency.daily => 'يومياً',
      BackupFrequency.weekly => 'أسبوعياً',
      BackupFrequency.monthly => 'شهرياً',
    };

BackupFrequency _backupFrequencyValue(String label) => switch (label) {
      'أسبوعياً' => BackupFrequency.weekly,
      'شهرياً' => BackupFrequency.monthly,
      'يدوياً' => BackupFrequency.manual,
      'عند إغلاق التطبيق' => BackupFrequency.manual,
      _ => BackupFrequency.daily,
    };

String _formatByteSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

String _shortChecksum(String checksum) {
  final prefixLength = checksum.length < 12 ? checksum.length : 12;
  return '${checksum.substring(0, prefixLength)}…';
}

String _formatAuditTimestamp(AuditTimestamp timestamp) {
  final local = timestamp.value.toLocal();
  final date = '${local.year.toString().padLeft(4, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.day.toString().padLeft(2, '0')}';
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'ص' : 'م';
  return '$date ${hour.toString().padLeft(2, '0')}:$minute $period';
}

String _serviceMessage(Object error) =>
    error is ServiceFailure ? error.message : 'تعذر إكمال العملية التجريبية';

int _nextEntitySequence(
  Iterable<EntityId> ids, {
  required int fallback,
}) {
  var maximum = 0;
  for (final id in ids) {
    final sequence = int.tryParse(id.value.split('-').last);
    if (sequence != null && sequence > maximum) maximum = sequence;
  }
  return maximum == 0 ? fallback : maximum + 1;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

class SettingsTemplatePanel extends StatelessWidget {
  const SettingsTemplatePanel({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
    super.key,
    this.expandChild = false,
    this.actions = const [],
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  final bool expandChild;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    final borderRadius = BorderRadius.circular(AppRadii.lg);
    final borderColor = Color.lerp(
      accentColor,
      AppColors.surface,
      0.62,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: borderRadius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: Color.alphaBlend(
                  accentColor.withAlpha(14),
                  AppColors.surface,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          accentColor.withAlpha(24),
                          AppColors.surface,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border:
                            Border.all(color: accentColor.withAlpha(90)),
                      ),
                      child: Icon(icon, color: accentColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: actions,
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              if (expandChild) Expanded(child: body) else body,
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsResponsiveGrid extends StatelessWidget {
  const SettingsResponsiveGrid({
    required this.children,
    super.key,
    this.preferredColumns = 2,
    this.spacing = AppSpacing.md,
    this.minimumChildHeight,
  });

  final List<Widget> children;
  final int preferredColumns;
  final double spacing;
  final double? minimumChildHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 1;
        if (constraints.maxWidth >= 1060 && preferredColumns >= 3) {
          columns = 3;
        } else if (constraints.maxWidth >= 650 && preferredColumns >= 2) {
          columns = 2;
        }
        if (columns > children.length) columns = children.length;

        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                child: minimumChildHeight == null
                    ? child
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: minimumChildHeight!,
                        ),
                        child: child,
                      ),
              ),
          ],
        );
      },
    );
  }
}

class SettingsTemplateTabs<T> extends StatelessWidget {
  const SettingsTemplateTabs({
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.keyPrefix,
    required this.accentColor,
    super.key,
  });

  final List<({T value, String label, IconData icon})> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final String keyPrefix;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          AppButton(
            key: Key('$keyPrefix${item.value}'),
            label: item.label,
            icon: item.icon,
            variant: item.value == selected
                ? AppButtonVariant.primary
                : AppButtonVariant.navigation,
            backgroundColor:
                item.value == selected ? accentColor : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            minWidth: 160,
            onPressed: item.value == selected
                ? () {}
                : () => onChanged(item.value),
          ),
      ],
    );
  }
}
