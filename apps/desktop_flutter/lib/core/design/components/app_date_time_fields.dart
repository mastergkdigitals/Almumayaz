import 'package:flutter/material.dart';

import '../app_formatters.dart';
import '../app_tokens.dart';
import 'app_date_picker_dialog.dart';
import 'app_header_button.dart';
import 'app_text_fields.dart';

class AppDateField extends StatefulWidget {
  const AppDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.fieldKey,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.accentColor,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final Key? fieldKey;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final Color? accentColor;

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textFor(widget.value));
  }

  @override
  void didUpdateWidget(covariant AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _textFor(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (!widget.enabled) return;

    final firstDate = widget.firstDate ?? DateTime(2000);
    final lastDate = widget.lastDate ?? DateTime(2100);
    var initialDate = widget.value ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final selected = await AppDatePickerDialog.show(
      context,
      initialDate: initialDate,
      selectedDate: widget.value,
      firstDate: firstDate,
      lastDate: lastDate,
      accentColor: widget.accentColor ?? AppColors.primary,
    );
    if (!mounted || selected == null) return;
    widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: widget.fieldKey,
      controller: _controller,
      label: widget.label,
      icon: Icons.calendar_month_rounded,
      accentColor: widget.accentColor,
      enabled: widget.enabled,
      readOnly: true,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      onTap: _pickDate,
      suffixIcon: AppTooltip(
        message: 'اختيار التاريخ',
        verticalOffset: AppControlHeights.large / 2 + AppSpacing.sm,
        child: AppFieldIconButton(
          icon: Icons.edit_calendar_rounded,
          color: widget.accentColor ?? AppColors.primary,
          onPressed: widget.enabled ? _pickDate : null,
        ),
      ),
    );
  }

  static String _textFor(DateTime? value) {
    return value == null ? '' : AppFormatters.date(value);
  }
}

class AppDateRangeField extends StatefulWidget {
  const AppDateRangeField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.fieldKey,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.accentColor,
  });

  final String label;
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange> onChanged;
  final Key? fieldKey;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final Color? accentColor;

  @override
  State<AppDateRangeField> createState() => _AppDateRangeFieldState();
}

class _AppDateRangeFieldState extends State<AppDateRangeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textFor(widget.value));
  }

  @override
  void didUpdateWidget(covariant AppDateRangeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRange(oldWidget.value, widget.value)) {
      _controller.text = _textFor(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    if (!widget.enabled) return;

    final firstDate = widget.firstDate ?? DateTime(2000);
    final lastDate = widget.lastDate ?? DateTime(2100);
    var initialDate = widget.value?.start ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final selected = await AppDateRangePickerDialog.show(
      context,
      initialDate: initialDate,
      selectedRange: widget.value,
      firstDate: firstDate,
      lastDate: lastDate,
      accentColor: widget.accentColor ?? AppColors.primary,
    );
    if (!mounted || selected == null) return;
    widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: widget.fieldKey,
      controller: _controller,
      label: widget.label,
      icon: Icons.date_range_rounded,
      accentColor: widget.accentColor,
      enabled: widget.enabled,
      readOnly: true,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      onTap: _pickRange,
      suffixIcon: AppTooltip(
        message: 'اختيار نطاق التاريخ',
        verticalOffset: AppControlHeights.large / 2 + AppSpacing.sm,
        child: AppFieldIconButton(
          icon: Icons.calendar_view_week_rounded,
          color: widget.accentColor ?? AppColors.primary,
          onPressed: widget.enabled ? _pickRange : null,
        ),
      ),
    );
  }

  static String _textFor(DateTimeRange? value) {
    if (value == null) return '';
    return 'من ${AppFormatters.date(value.start)} '
        'إلى ${AppFormatters.date(value.end)}';
  }

  static bool _sameRange(DateTimeRange? first, DateTimeRange? second) {
    return first?.start == second?.start && first?.end == second?.end;
  }
}

class AppTimeField extends StatefulWidget {
  const AppTimeField({
    required this.label,
    required this.value,
    super.key,
    this.fieldKey,
    this.onChanged,
    this.enabled = false,
    this.accentColor,
  });

  final String label;
  final TimeOfDay? value;

  /// Kept for source compatibility. Time fields are always system-generated.
  final ValueChanged<TimeOfDay>? onChanged;
  final Key? fieldKey;

  /// Kept for source compatibility. Time fields are always disabled.
  final bool enabled;
  final Color? accentColor;

  @override
  State<AppTimeField> createState() => _AppTimeFieldState();
}

class _AppTimeFieldState extends State<AppTimeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textFor(widget.value));
  }

  @override
  void didUpdateWidget(covariant AppTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _textFor(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppReadOnlyField(
      fieldKey: widget.fieldKey,
      controller: _controller,
      label: widget.label,
      icon: Icons.schedule_rounded,
      accentColor: widget.accentColor,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }

  static String _textFor(TimeOfDay? value) {
    return value == null ? '' : AppFormatters.time(value);
  }
}
