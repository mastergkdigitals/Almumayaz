import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_shortcuts.dart';

abstract final class AppDatePickerDialog {
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? selectedDate,
    DateTime? firstDate,
    DateTime? lastDate,
    Color accentColor = AppColors.primary,
  }) {
    final minimum = _dateOnly(firstDate ?? DateTime(2000));
    final maximum = _dateOnly(lastDate ?? DateTime(2100));
    var initial = _dateOnly(selectedDate ?? initialDate);
    if (initial.isBefore(minimum)) initial = minimum;
    if (initial.isAfter(maximum)) initial = maximum;

    return showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _AppDatePickerBody(
          initialDate: initial,
          firstDate: minimum,
          lastDate: maximum,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _AppDatePickerBody extends StatefulWidget {
  const _AppDatePickerBody({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.accentColor,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color accentColor;

  @override
  State<_AppDatePickerBody> createState() => _AppDatePickerBodyState();
}

class _AppDatePickerBodyState extends State<_AppDatePickerBody> {
  static const _monthNames = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  static const _weekdayLabels = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  bool get _canGoPrevious {
    final previous = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    return !DateTime(previous.year, previous.month + 1, 0)
        .isBefore(widget.firstDate);
  }

  bool get _canGoNext {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    return !next.isAfter(widget.lastDate);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
    });
  }

  bool _isEnabled(DateTime date) {
    return !date.isBefore(widget.firstDate) && !date.isAfter(widget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    return AppShortcutScope(
      onEscape: () => Navigator.of(context).pop(),
      child: Dialog(
        key: const Key('appDatePickerDialog'),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadii.xl),
              boxShadow: AppShadows.soft,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'اختر التاريخ',
                    textAlign: TextAlign.center,
                    style: AppTypography.screenTitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _MonthHeader(
                    title:
                        '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                    onPrevious: _canGoPrevious
                        ? () => _changeMonth(-1)
                        : null,
                    onNext:
                        _canGoNext ? () => _changeMonth(1) : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _WeekdayHeader(labels: _weekdayLabels),
                  const SizedBox(height: AppSpacing.sm),
                  _CalendarGrid(
                    visibleMonth: _visibleMonth,
                    selectedDate: _selectedDate,
                    accentColor: widget.accentColor,
                    isEnabled: _isEnabled,
                    onSelected: (date) =>
                        setState(() => _selectedDate = date),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        key: const Key('appDatePickerCancel'),
                        label: 'إلغاء',
                        variant: AppButtonVariant.secondary,
                        width: 108,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        key: const Key('appDatePickerConfirm'),
                        label: 'موافق',
                        icon: Icons.check_rounded,
                        width: 108,
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedDate),
                      ),
                    ],
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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppButton(
          label: '',
          icon: Icons.chevron_left_rounded,
          width: AppControlHeights.compact,
          height: AppControlHeights.compact,
          padding: EdgeInsets.zero,
          variant: AppButtonVariant.navigation,
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        AppButton(
          label: '',
          icon: Icons.chevron_right_rounded,
          width: AppControlHeights.compact,
          height: AppControlHeights.compact,
          padding: EdgeInsets.zero,
          variant: AppButtonVariant.navigation,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.tableHeader.copyWith(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.accentColor,
    required this.isEnabled,
    required this.onSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final Color accentColor;
  final bool Function(DateTime) isEnabled;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final dayCount = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final cells = List<DateTime?>.filled(42, null);
    final offset = (firstDay.weekday + 1) % DateTime.daysPerWeek;

    for (var day = 1; day <= dayCount; day++) {
      cells[offset + day - 1] =
          DateTime(visibleMonth.year, visibleMonth.month, day);
    }

    return Column(
      children: [
        for (var row = 0; row < 6; row++)
          Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : AppSpacing.xs),
            child: Row(
              children: [
                for (final date in cells.skip(row * 7).take(7))
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 2),
                      child: date == null
                          ? const SizedBox(height: 42)
                          : _DayButton(
                              date: date,
                              selected:
                                  DateUtils.isSameDay(date, selectedDate),
                              today:
                                  DateUtils.isSameDay(date, DateTime.now()),
                              enabled: isEnabled(date),
                              accentColor: accentColor,
                              onPressed: () => onSelected(date),
                            ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.date,
    required this.selected,
    required this.today,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  final DateTime date;
  final bool selected;
  final bool today;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = selected ? accentColor : Colors.transparent;
    final foreground = !enabled
        ? AppColors.disabled
        : selected
            ? AppColors.onStrong
            : AppColors.textPrimary;

    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.zero,
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
          shadowColor:
              const WidgetStatePropertyAll<Color>(Colors.transparent),
          surfaceTintColor:
              const WidgetStatePropertyAll<Color>(Colors.transparent),
          overlayColor:
              const WidgetStatePropertyAll<Color>(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          mouseCursor: WidgetStateProperty.resolveWith<MouseCursor?>(
            (states) => states.contains(WidgetState.disabled)
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
          ),
          backgroundColor: WidgetStatePropertyAll<Color>(background),
          foregroundColor: WidgetStatePropertyAll<Color>(foreground),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(
              color:
                  selected || today ? accentColor : Colors.transparent,
              width: today && !selected ? 1.4 : 1,
            ),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
        ),
        child: Text(
          '${date.day}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
