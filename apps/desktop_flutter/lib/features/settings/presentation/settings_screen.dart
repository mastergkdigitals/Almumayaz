import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

const _purchaseGreen = Color(0xFF10966A);
const _purchaseGreenDark = Color(0xFF075E45);
const _purchaseGreenSoft = Color(0xFFE8F7F0);
const _purchaseGreenPale = Color(0xFFF5FCF8);
const _purchaseLine = Color(0xFFD4E9DF);
const _purchaseDanger = Color(0xFFD94A4A);
const _templateMinimumWidth = 920.0;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<List<_PreviewRow>> _templateRows = List.generate(
    4,
    (index) => _createPreviewRows(index + 1),
  );
  final _nextRowNumbers = <int>[4, 4, 4, 4];

  void _addRow(int templateIndex) {
    setState(() {
      final templateNumber = templateIndex + 1;
      final rowNumber = _nextRowNumbers[templateIndex]++;
      _templateRows[templateIndex].add(
        _PreviewRow(
          id: 't$templateNumber-r$rowNumber',
          code: '',
          name: '',
          quantity: '0',
          price: '0',
        ),
      );
    });
  }

  void _deleteRow(int templateIndex, _PreviewRow row) {
    setState(() {
      _templateRows[templateIndex].remove(row);
    });
  }

  void _updateRow(
    _PreviewRow row,
    _PreviewField field,
    String value,
  ) {
    setState(() {
      if (field == _PreviewField.code) {
        row.code = value;
      } else if (field == _PreviewField.name) {
        row.name = value;
      } else if (field == _PreviewField.quantity) {
        row.quantity = value;
      } else {
        row.price = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      key: const Key('settingsScreen'),
      title: 'الإعدادات',
      subtitle: 'مقارنة أربعة تصاميم جديدة لجدول المشتريات',
      onBack: () => Navigator.of(context).pop(),
      body: ColoredBox(
        color: const Color(0xFFF8FBFA),
        child: SingleChildScrollView(
          key: const Key('settingsTemplatesScroll'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppInfoBanner(
                    message:
                        'أربعة اتجاهات جديدة بالكامل لجدول المشتريات. '
                        'اكتب داخل الخلايا وأضف الصفوف أو احذفها قبل الاختيار.',
                    icon: Icons.dashboard_customize_rounded,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TemplatePanel(
                    key: const Key('settingsTemplatePanel1'),
                    label: 'نموذج 1',
                    title: 'صفوف بطاقات هوائية',
                    description:
                        'صفوف مستقلة ومسافات مريحة مع سطح أبيض خفيف.',
                    badge: 'واسع',
                    child: _CardRowsTable(
                      key: const Key('purchaseTableTemplate1'),
                      rows: _templateRows[0],
                      onAdd: () => _addRow(0),
                      onDelete: (row) => _deleteRow(0, row),
                      onChanged: _updateRow,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TemplatePanel(
                    key: const Key('settingsTemplatePanel2'),
                    label: 'نموذج 2',
                    title: 'شبكة احترافية مضغوطة',
                    description:
                        'رأس أخضر واضح وصفوف كثيفة للعرض السريع.',
                    badge: 'مضغوط',
                    child: _CompactGridTable(
                      key: const Key('purchaseTableTemplate2'),
                      rows: _templateRows[1],
                      onAdd: () => _addRow(1),
                      onDelete: (row) => _deleteRow(1, row),
                      onChanged: _updateRow,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TemplatePanel(
                    key: const Key('settingsTemplatePanel3'),
                    label: 'نموذج 3',
                    title: 'خلايا ناعمة منفصلة',
                    description:
                        'كل قيمة داخل مساحة مستقلة بحدود هادئة وواضحة.',
                    badge: 'مرن',
                    child: _SoftCellsTable(
                      key: const Key('purchaseTableTemplate3'),
                      rows: _templateRows[2],
                      onAdd: () => _addRow(2),
                      onDelete: (row) => _deleteRow(2, row),
                      onChanged: _updateRow,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TemplatePanel(
                    key: const Key('settingsTemplatePanel4'),
                    label: 'نموذج 4',
                    title: 'سجل مشتريات حديث',
                    description:
                        'صفوف محاسبية بخطوط إرشادية وشريط ملخص سفلي.',
                    badge: 'تفصيلي',
                    child: _ModernLedgerTable(
                      key: const Key('purchaseTableTemplate4'),
                      rows: _templateRows[3],
                      onAdd: () => _addRow(3),
                      onDelete: (row) => _deleteRow(3, row),
                      onChanged: _updateRow,
                    ),
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

class _TemplatePanel extends StatelessWidget {
  const _TemplatePanel({
    super.key,
    required this.label,
    required this.title,
    required this.description,
    required this.badge,
    required this.child,
  });

  final String label;
  final String title;
  final String description;
  final String badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: _purchaseLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D075E45),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _purchaseGreen,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.sectionTitle.copyWith(
                        color: _purchaseGreenDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _purchaseGreenSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _purchaseLine),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: _purchaseGreenDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _PreviewViewport extends StatelessWidget {
  const _PreviewViewport({required this.builder});

  final Widget Function(double width) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < _templateMinimumWidth
            ? _templateMinimumWidth
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: builder(width),
          ),
        );
      },
    );
  }
}

class _PreviewWidths {
  const _PreviewWidths({
    required this.index,
    required this.code,
    required this.name,
    required this.quantity,
    required this.price,
    required this.action,
  });

  factory _PreviewWidths.forWidth(double width) {
    const index = 64.0;
    const code = 170.0;
    const quantity = 130.0;
    const price = 170.0;
    const action = 82.0;

    return _PreviewWidths(
      index: index,
      code: code,
      name: width - index - code - quantity - price - action,
      quantity: quantity,
      price: price,
      action: action,
    );
  }

  final double index;
  final double code;
  final double name;
  final double quantity;
  final double price;
  final double action;
}

class _CardRowsTable extends StatelessWidget {
  const _CardRowsTable({
    super.key,
    required this.rows,
    required this.onAdd,
    required this.onDelete,
    required this.onChanged,
  });

  final List<_PreviewRow> rows;
  final VoidCallback onAdd;
  final ValueChanged<_PreviewRow> onDelete;
  final _PreviewRowChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return _PreviewViewport(
      builder: (width) {
        final widths = _PreviewWidths.forWidth(width - 24);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _purchaseGreenPale,
            borderRadius: BorderRadius.circular(20),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _purchaseLine),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                    _HeaderText('ت', widths.index, _purchaseGreenDark),
                    _HeaderText('رمز المادة', widths.code, _purchaseGreenDark),
                    _HeaderText('اسم المادة', widths.name, _purchaseGreenDark),
                    _HeaderText('الكمية', widths.quantity, _purchaseGreenDark),
                    _HeaderText('السعر', widths.price, _purchaseGreenDark),
                    SizedBox(
                      width: widths.action,
                      child: Center(
                        child: _PreviewIconButton(
                          key: _previewAddKey(1),
                          icon: Icons.add_rounded,
                          tooltip: 'إضافة مادة',
                          foreground: Colors.white,
                          background: _purchaseGreen,
                          borderColor: _purchaseGreen,
                          borderRadius: 12,
                          onPressed: onAdd,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < rows.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                Container(
                  key: _previewRowKey(1, rows[index]),
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A075E45),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE1EEE8)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: widths.index,
                        child: Center(
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: _purchaseGreenSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: _purchaseGreenDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _EditableValueCell(
                        fieldKey: _previewFieldKey(
                          1,
                          rows[index],
                          _PreviewField.code,
                        ),
                        initialValue: rows[index].code,
                        width: widths.code,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        fontWeight: FontWeight.w800,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.code,
                          value,
                        ),
                      ),
                      _EditableValueCell(
                        fieldKey: _previewFieldKey(
                          1,
                          rows[index],
                          _PreviewField.name,
                        ),
                        initialValue: rows[index].name,
                        width: widths.name,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.name,
                          value,
                        ),
                      ),
                      _EditableValueCell(
                        fieldKey: _previewFieldKey(
                          1,
                          rows[index],
                          _PreviewField.quantity,
                        ),
                        initialValue: rows[index].quantity,
                        width: widths.quantity,
                        inputKind: _PreviewInputKind.wholeNumber,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.quantity,
                          value,
                        ),
                      ),
                      _EditableValueCell(
                        fieldKey: _previewFieldKey(
                          1,
                          rows[index],
                          _PreviewField.price,
                        ),
                        initialValue: rows[index].price,
                        width: widths.price,
                        inputKind: _PreviewInputKind.amount,
                        color: _purchaseGreenDark,
                        fontWeight: FontWeight.w800,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.price,
                          value,
                        ),
                      ),
                      SizedBox(
                        width: widths.action,
                        child: Center(
                          child: _PreviewIconButton(
                            key: _previewDeleteKey(1, rows[index]),
                            icon: Icons.close_rounded,
                            tooltip: 'حذف السطر',
                            foreground: _purchaseDanger,
                            background: const Color(0xFFFFF3F3),
                            borderColor: const Color(0xFFF3C8C8),
                            borderRadius: 12,
                            onPressed: () => onDelete(rows[index]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CompactGridTable extends StatelessWidget {
  const _CompactGridTable({
    super.key,
    required this.rows,
    required this.onAdd,
    required this.onDelete,
    required this.onChanged,
  });

  final List<_PreviewRow> rows;
  final VoidCallback onAdd;
  final ValueChanged<_PreviewRow> onDelete;
  final _PreviewRowChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return _PreviewViewport(
      builder: (width) {
        final widths = _PreviewWidths.forWidth(width);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDCCF)),
          ),
          child: Column(
            children: [
              Container(
                key: const Key('settingsTemplate2Header'),
                height: 50,
                color: _purchaseGreenDark,
                child: Row(
                  children: [
                    _HeaderText('ت', widths.index, Colors.white),
                    _HeaderText('رمز المادة', widths.code, Colors.white),
                    _HeaderText('اسم المادة', widths.name, Colors.white),
                    _HeaderText('الكمية', widths.quantity, Colors.white),
                    _HeaderText('السعر', widths.price, Colors.white),
                    SizedBox(
                      width: widths.action,
                      child: Center(
                        child: _PreviewIconButton(
                          key: _previewAddKey(2),
                          icon: Icons.add_rounded,
                          tooltip: 'إضافة مادة',
                          foreground: _purchaseGreenDark,
                          background: Colors.white,
                          borderColor: Colors.white,
                          borderRadius: 999,
                          size: 32,
                          onPressed: onAdd,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < rows.length; index++)
                Container(
                  key: _previewRowKey(2, rows[index]),
                  height: 54,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Colors.white
                        : const Color(0xFFF0F9F5),
                    border: const Border(
                      bottom: BorderSide(color: _purchaseLine),
                    ),
                  ),
                  child: Row(
                    children: [
                      _GridValueCell(
                        '${index + 1}',
                        widths.index,
                        fontWeight: FontWeight.w800,
                      ),
                      _GridEditableCell(
                        fieldKey: _previewFieldKey(
                          2,
                          rows[index],
                          _PreviewField.code,
                        ),
                        initialValue: rows[index].code,
                        width: widths.code,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        fontWeight: FontWeight.w800,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.code,
                          value,
                        ),
                      ),
                      _GridEditableCell(
                        fieldKey: _previewFieldKey(
                          2,
                          rows[index],
                          _PreviewField.name,
                        ),
                        initialValue: rows[index].name,
                        width: widths.name,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.name,
                          value,
                        ),
                      ),
                      _GridEditableCell(
                        fieldKey: _previewFieldKey(
                          2,
                          rows[index],
                          _PreviewField.quantity,
                        ),
                        initialValue: rows[index].quantity,
                        width: widths.quantity,
                        inputKind: _PreviewInputKind.wholeNumber,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.quantity,
                          value,
                        ),
                      ),
                      _GridEditableCell(
                        fieldKey: _previewFieldKey(
                          2,
                          rows[index],
                          _PreviewField.price,
                        ),
                        initialValue: rows[index].price,
                        width: widths.price,
                        inputKind: _PreviewInputKind.amount,
                        color: _purchaseGreenDark,
                        fontWeight: FontWeight.w800,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.price,
                          value,
                        ),
                      ),
                      SizedBox(
                        width: widths.action,
                        child: Center(
                          child: _PreviewIconButton(
                            key: _previewDeleteKey(2, rows[index]),
                            icon: Icons.close_rounded,
                            tooltip: 'حذف السطر',
                            foreground: _purchaseDanger,
                            background: Colors.transparent,
                            borderColor: const Color(0xFFE7BABA),
                            borderRadius: 999,
                            size: 32,
                            onPressed: () => onDelete(rows[index]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SoftCellsTable extends StatelessWidget {
  const _SoftCellsTable({
    super.key,
    required this.rows,
    required this.onAdd,
    required this.onDelete,
    required this.onChanged,
  });

  final List<_PreviewRow> rows;
  final VoidCallback onAdd;
  final ValueChanged<_PreviewRow> onDelete;
  final _PreviewRowChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return _PreviewViewport(
      builder: (width) {
        final widths = _PreviewWidths.forWidth(width - 28);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7F5),
            borderRadius: BorderRadius.circular(20),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE9E3)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    _SoftHeaderCell('ت', widths.index),
                    _SoftHeaderCell('رمز المادة', widths.code),
                    _SoftHeaderCell('اسم المادة', widths.name),
                    _SoftHeaderCell('الكمية', widths.quantity),
                    _SoftHeaderCell('السعر', widths.price),
                    SizedBox(width: widths.action),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              for (var index = 0; index < rows.length; index++)
                SizedBox(
                  key: _previewRowKey(3, rows[index]),
                  height: 68,
                  child: Row(
                    children: [
                      _SoftDataCell(
                        width: widths.index,
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? _purchaseGreen
                                : _purchaseGreenSoft,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Text(
                            '${index + 1}',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: index == 0
                                  ? Colors.white
                                  : _purchaseGreenDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      _SoftDataCell(
                        width: widths.code,
                        fieldKey: _previewFieldKey(
                          3,
                          rows[index],
                          _PreviewField.code,
                        ),
                        initialValue: rows[index].code,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        emphasized: true,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.code,
                          value,
                        ),
                      ),
                      _SoftDataCell(
                        width: widths.name,
                        fieldKey: _previewFieldKey(
                          3,
                          rows[index],
                          _PreviewField.name,
                        ),
                        initialValue: rows[index].name,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.name,
                          value,
                        ),
                      ),
                      _SoftDataCell(
                        width: widths.quantity,
                        fieldKey: _previewFieldKey(
                          3,
                          rows[index],
                          _PreviewField.quantity,
                        ),
                        initialValue: rows[index].quantity,
                        inputKind: _PreviewInputKind.wholeNumber,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.quantity,
                          value,
                        ),
                      ),
                      _SoftDataCell(
                        width: widths.price,
                        fieldKey: _previewFieldKey(
                          3,
                          rows[index],
                          _PreviewField.price,
                        ),
                        initialValue: rows[index].price,
                        inputKind: _PreviewInputKind.amount,
                        emphasized: true,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.price,
                          value,
                        ),
                      ),
                      SizedBox(
                        width: widths.action,
                        child: Center(
                          child: _PreviewIconButton(
                            key: _previewDeleteKey(3, rows[index]),
                            icon: Icons.close_rounded,
                            tooltip: 'حذف السطر',
                            foreground: _purchaseDanger,
                            background: Colors.white,
                            borderColor: const Color(0xFFE8C8C8),
                            borderRadius: 13,
                            size: 36,
                            onPressed: () => onDelete(rows[index]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: _PreviewWideButton(
                  key: _previewAddKey(3),
                  label: 'إضافة مادة',
                  icon: Icons.add_rounded,
                  onPressed: onAdd,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModernLedgerTable extends StatelessWidget {
  const _ModernLedgerTable({
    super.key,
    required this.rows,
    required this.onAdd,
    required this.onDelete,
    required this.onChanged,
  });

  final List<_PreviewRow> rows;
  final VoidCallback onAdd;
  final ValueChanged<_PreviewRow> onDelete;
  final _PreviewRowChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return _PreviewViewport(
      builder: (width) {
        final widths = _PreviewWidths.forWidth(width);
        final total = rows.fold<num>(0, (sum, row) {
          final quantity = AppFormatters.parseInteger(row.quantity) ?? 0;
          final price = AppFormatters.parseNumber(row.price) ?? 0;
          return sum + quantity * price;
        });
        final rowCountLabel = rows.length == 1
            ? 'مادة واحدة جاهزة للمراجعة'
            : '${rows.length} مواد جاهزة للمراجعة';

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _purchaseLine),
          ),
          child: Column(
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: _purchaseGreenPale,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: _purchaseGreen,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rowCountLabel,
                            style: const TextStyle(
                              color: _purchaseGreenDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PreviewWideButton(
                      key: _previewAddKey(4),
                      label: 'إضافة مادة',
                      icon: Icons.add_rounded,
                      compact: true,
                      onPressed: onAdd,
                    ),
                  ],
                ),
              ),
              Container(
                key: const Key('settingsTemplate4Header'),
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: _purchaseGreen,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _HeaderText('ت', widths.index, _purchaseGreenDark),
                    _HeaderText(
                      'رمز المادة',
                      widths.code,
                      _purchaseGreenDark,
                    ),
                    _HeaderText(
                      'اسم المادة',
                      widths.name,
                      _purchaseGreenDark,
                    ),
                    _HeaderText(
                      'الكمية',
                      widths.quantity,
                      _purchaseGreenDark,
                    ),
                    _HeaderText('السعر', widths.price, _purchaseGreenDark),
                    SizedBox(width: widths.action),
                  ],
                ),
              ),
              for (var index = 0; index < rows.length; index++)
                Container(
                  key: _previewRowKey(4, rows[index]),
                  height: 60,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Colors.white
                        : const Color(0xFFFAFCFB),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFE7F0EC)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: widths.index,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: _purchaseGreen,
                              width: 4,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: _purchaseGreenDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: widths.code,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _purchaseGreenSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _InlineEditor(
                            fieldKey: _previewFieldKey(
                              4,
                              rows[index],
                              _PreviewField.code,
                            ),
                            initialValue: rows[index].code,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            color: _purchaseGreenDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            onChanged: (value) => onChanged(
                              rows[index],
                              _PreviewField.code,
                              value,
                            ),
                          ),
                        ),
                      ),
                      _EditableValueCell(
                        fieldKey: _previewFieldKey(
                          4,
                          rows[index],
                          _PreviewField.name,
                        ),
                        initialValue: rows[index].name,
                        width: widths.name,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.name,
                          value,
                        ),
                      ),
                      SizedBox(
                        width: widths.quantity,
                        child: Center(
                          child: Container(
                            width: 82,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: _InlineEditor(
                              fieldKey: _previewFieldKey(
                                4,
                                rows[index],
                                _PreviewField.quantity,
                              ),
                              initialValue: rows[index].quantity,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              inputKind: _PreviewInputKind.wholeNumber,
                              onChanged: (value) => onChanged(
                                rows[index],
                                _PreviewField.quantity,
                                value,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _EditableValueCell(
                        fieldKey: _previewFieldKey(
                          4,
                          rows[index],
                          _PreviewField.price,
                        ),
                        initialValue: rows[index].price,
                        width: widths.price,
                        inputKind: _PreviewInputKind.amount,
                        color: _purchaseGreenDark,
                        fontWeight: FontWeight.w900,
                        onChanged: (value) => onChanged(
                          rows[index],
                          _PreviewField.price,
                          value,
                        ),
                      ),
                      SizedBox(
                        width: widths.action,
                        child: Center(
                          child: _PreviewIconButton(
                            key: _previewDeleteKey(4, rows[index]),
                            icon: Icons.close_rounded,
                            tooltip: 'حذف السطر',
                            foreground: _purchaseDanger,
                            background: Colors.transparent,
                            borderColor: Colors.transparent,
                            borderRadius: 999,
                            size: 34,
                            onPressed: () => onDelete(rows[index]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                color: _purchaseGreenSoft,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الإجمالي التقريبي',
                        style: TextStyle(
                          color: _purchaseGreenDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${AppFormatters.iqd(total)} د.ع',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: _purchaseGreenDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.label, this.width, this.color);

  final String label;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InlineEditor extends StatelessWidget {
  const _InlineEditor({
    required this.fieldKey,
    required this.initialValue,
    required this.onChanged,
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.color = AppColors.textPrimary,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w700,
    this.inputKind = _PreviewInputKind.text,
  });

  final Key fieldKey;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final _PreviewInputKind inputKind;

  @override
  Widget build(BuildContext context) {
    final inputFormatters = switch (inputKind) {
      _PreviewInputKind.text => null,
      _PreviewInputKind.wholeNumber => <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
      _PreviewInputKind.amount => <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
    };
    final keyboardType = switch (inputKind) {
      _PreviewInputKind.text => TextInputType.text,
      _PreviewInputKind.wholeNumber => TextInputType.number,
      _PreviewInputKind.amount =>
          const TextInputType.numberWithOptions(decimal: true),
    };

    return TextFormField(
      key: fieldKey,
      initialValue: initialValue,
      maxLines: 1,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      textDirection: textDirection,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1,
      ),
      decoration: const InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
    );
  }
}

class _EditableValueCell extends StatelessWidget {
  const _EditableValueCell({
    required this.fieldKey,
    required this.initialValue,
    required this.width,
    required this.onChanged,
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.color = AppColors.textPrimary,
    this.fontWeight = FontWeight.w700,
    this.inputKind = _PreviewInputKind.text,
  });

  final Key fieldKey;
  final String initialValue;
  final double width;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Color color;
  final FontWeight fontWeight;
  final _PreviewInputKind inputKind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _InlineEditor(
          fieldKey: fieldKey,
          initialValue: initialValue,
          onChanged: onChanged,
          textAlign: textAlign,
          textDirection: textDirection,
          color: color,
          fontWeight: fontWeight,
          inputKind: inputKind,
        ),
      ),
    );
  }
}

class _GridValueCell extends StatelessWidget {
  const _GridValueCell(
    this.value,
    this.width, {
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.color = AppColors.textPrimary,
    this.fontWeight = FontWeight.w700,
  });

  final String value;
  final double width;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: _purchaseLine),
        ),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        textDirection: textDirection,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class _GridEditableCell extends StatelessWidget {
  const _GridEditableCell({
    required this.fieldKey,
    required this.initialValue,
    required this.width,
    required this.onChanged,
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.color = AppColors.textPrimary,
    this.fontWeight = FontWeight.w700,
    this.inputKind = _PreviewInputKind.text,
  });

  final Key fieldKey;
  final String initialValue;
  final double width;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Color color;
  final FontWeight fontWeight;
  final _PreviewInputKind inputKind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: _purchaseLine),
        ),
      ),
      child: _InlineEditor(
        fieldKey: fieldKey,
        initialValue: initialValue,
        onChanged: onChanged,
        textAlign: textAlign,
        textDirection: textDirection,
        color: color,
        fontSize: 14,
        fontWeight: fontWeight,
        inputKind: inputKind,
      ),
    );
  }
}

class _SoftHeaderCell extends StatelessWidget {
  const _SoftHeaderCell(this.label, this.width);

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _purchaseLine),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _purchaseGreenDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftDataCell extends StatelessWidget {
  const _SoftDataCell({
    required this.width,
    this.fieldKey,
    this.initialValue,
    this.onChanged,
    this.child,
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.emphasized = false,
    this.inputKind = _PreviewInputKind.text,
  }) : assert(
          child != null ||
              (fieldKey != null &&
                  initialValue != null &&
                  onChanged != null),
        );

  final double width;
  final Key? fieldKey;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final Widget? child;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final bool emphasized;
  final _PreviewInputKind inputKind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: child ??
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: emphasized
                      ? const Color(0xFFB8DDCC)
                      : const Color(0xFFDCE9E3),
                ),
              ),
              child: _InlineEditor(
                fieldKey: fieldKey!,
                initialValue: initialValue!,
                onChanged: onChanged!,
                textAlign: textAlign,
                textDirection: textDirection,
                color: emphasized
                    ? _purchaseGreenDark
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight:
                    emphasized ? FontWeight.w800 : FontWeight.w700,
                inputKind: inputKind,
              ),
            ),
      ),
    );
  }
}

class _PreviewIconButton extends StatelessWidget {
  const _PreviewIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.foreground,
    required this.background,
    required this.borderColor,
    required this.borderRadius,
    required this.onPressed,
    this.size = 34,
  });

  final IconData icon;
  final String tooltip;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final double borderRadius;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: foreground, size: 19),
          ),
        ),
      ),
    );
  }
}

class _PreviewWideButton extends StatelessWidget {
  const _PreviewWideButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _purchaseGreen,
      borderRadius: BorderRadius.circular(compact ? 9 : 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 9 : 12),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 7 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: compact ? 17 : 19),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow {
  _PreviewRow({
    required this.id,
    required this.code,
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String id;
  String code;
  String name;
  String quantity;
  String price;
}

enum _PreviewField { code, name, quantity, price }

enum _PreviewInputKind { text, wholeNumber, amount }

typedef _PreviewRowChanged = void Function(
  _PreviewRow row,
  _PreviewField field,
  String value,
);

List<_PreviewRow> _createPreviewRows(int templateNumber) {
  return [
    _PreviewRow(
      id: 't$templateNumber-r1',
      code: 'P-001',
      name: 'دفتر ملاحظات',
      quantity: '100',
      price: '2,500',
    ),
    _PreviewRow(
      id: 't$templateNumber-r2',
      code: 'P-002',
      name: 'قلم أزرق',
      quantity: '1,000',
      price: '1,250',
    ),
    _PreviewRow(
      id: 't$templateNumber-r3',
      code: 'P-003',
      name: 'طابعة مكتبية',
      quantity: '2',
      price: '175,000',
    ),
  ];
}

Key _previewRowKey(int templateNumber, _PreviewRow row) {
  return Key('template${templateNumber}Row-${row.id}');
}

Key _previewAddKey(int templateNumber) {
  return Key('template${templateNumber}AddRow');
}

Key _previewDeleteKey(int templateNumber, _PreviewRow row) {
  return Key('template${templateNumber}DeleteRow-${row.id}');
}

Key _previewFieldKey(
  int templateNumber,
  _PreviewRow row,
  _PreviewField field,
) {
  final fieldName = switch (field) {
    _PreviewField.code => 'Code',
    _PreviewField.name => 'Name',
    _PreviewField.quantity => 'Quantity',
    _PreviewField.price => 'Price',
  };

  return Key('template$templateNumber${fieldName}Field-${row.id}');
}
