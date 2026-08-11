import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_formatters.dart';
import '../app_tokens.dart';
import 'app_date_picker_dialog.dart';
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
    this.showPickerButton = true,
    this.textDirection = TextDirection.ltr,
    this.textAlign = TextAlign.right,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final Key? fieldKey;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final Color? accentColor;
  final bool showPickerButton;
  final TextDirection textDirection;
  final TextAlign textAlign;

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
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: '${widget.label}، اضغط Enter أو Space لاختيار التاريخ',
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _pickDate,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _pickDate,
          const SingleActivator(LogicalKeyboardKey.space): _pickDate,
        },
        child: AppTextField(
          fieldKey: widget.fieldKey,
          controller: _controller,
          label: widget.label,
          icon: Icons.calendar_month_rounded,
          accentColor: widget.accentColor,
          enabled: widget.enabled,
          readOnly: true,
          textDirection: widget.textDirection,
          textAlign: widget.textAlign,
          onTap: _pickDate,
          onSubmitted: (_) => _pickDate(),
          suffixIcon: widget.showPickerButton
              ? AppFieldIconButton(
                  icon: Icons.edit_calendar_rounded,
                  tooltip: 'اختيار التاريخ',
                  color: widget.accentColor ?? AppColors.primary,
                  onPressed: widget.enabled ? _pickDate : null,
                )
              : null,
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
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: '${widget.label}، اضغط Enter أو Space لاختيار نطاق التاريخ',
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _pickRange,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _pickRange,
          const SingleActivator(LogicalKeyboardKey.space): _pickRange,
        },
        child: AppTextField(
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
          onSubmitted: (_) => _pickRange(),
          suffixIcon: AppFieldIconButton(
            icon: Icons.calendar_view_week_rounded,
            tooltip: 'اختيار نطاق التاريخ',
            color: widget.accentColor ?? AppColors.primary,
            onPressed: widget.enabled ? _pickRange : null,
          ),
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
    this.accentColor,
  });

  final String label;
  final TimeOfDay? value;
  final Key? fieldKey;
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
