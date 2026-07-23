import 'package:flutter/material.dart';

import '../app_formatters.dart';
import '../app_tokens.dart';
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

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
      onTap: () => _pickDate(),
      suffixIcon: AppFieldIconButton(
        icon: Icons.edit_calendar_rounded,
        tooltip: 'اختيار التاريخ',
        color: widget.accentColor ?? AppColors.primary,
        onPressed: widget.enabled ? () => _pickDate() : null,
      ),
    );
  }

  static String _textFor(DateTime? value) {
    return value == null ? '' : AppFormatters.date(value);
  }
}

class AppTimeField extends StatefulWidget {
  const AppTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.fieldKey,
    this.enabled = true,
    this.accentColor,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final Key? fieldKey;
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

  Future<void> _pickTime() async {
    if (!widget.enabled) return;

    final selected = await showTimePicker(
      context: context,
      initialTime: widget.value ?? TimeOfDay.now(),
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
      icon: Icons.schedule_rounded,
      accentColor: widget.accentColor,
      enabled: widget.enabled,
      readOnly: true,
      onTap: () => _pickTime(),
      suffixIcon: AppFieldIconButton(
        icon: Icons.access_time_filled_rounded,
        tooltip: 'اختيار الوقت',
        color: widget.accentColor ?? AppColors.primary,
        onPressed: widget.enabled ? () => _pickTime() : null,
      ),
    );
  }

  static String _textFor(TimeOfDay? value) {
    return value == null ? '' : AppFormatters.time(value);
  }
}
