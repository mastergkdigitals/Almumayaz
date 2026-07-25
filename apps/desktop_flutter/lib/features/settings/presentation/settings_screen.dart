import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

const _purchaseGreen = Color(0xFF10966A);
const _purchaseGreenDark = Color(0xFF075E45);
const _purchaseGreenSoft = Color(0xFFE8F7F0);
const _purchaseGreenPale = Color(0xFFF5FCF8);
const _purchaseLine = Color(0xFFD4E9DF);
const _purchaseDanger = Color(0xFFD94A4A);
const _templateMinimumWidth = 920.0;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void showPreviewMessage() {
      AppToast.showInfo(context, 'هذا نموذج للمقارنة البصرية فقط');
    }

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
                        'قارن بينها واختر النموذج الأقرب لذوقك.',
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
                      onAction: showPreviewMessage,
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
                      onAction: showPreviewMessage,
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
                      onAction: showPreviewMessage,
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
                      onAction: showPreviewMessage,
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
    required this.onAction,
  });

  final VoidCallback onAction;

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
                          icon: Icons.add_rounded,
                          tooltip: 'إضافة مادة',
                          foreground: Colors.white,
                          background: _purchaseGreen,
                          borderColor: _purchaseGreen,
                          borderRadius: 12,
                          onPressed: onAction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < _previewRows.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                Container(
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
                      _ValueText(
                        _previewRows[index].code,
                        widths.code,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        fontWeight: FontWeight.w800,
                      ),
                      _ValueText(
                        _previewRows[index].name,
                        widths.name,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      _ValueText(
                        _previewRows[index].quantity,
                        widths.quantity,
                      ),
                      _ValueText(
                        _previewRows[index].price,
                        widths.price,
                        color: _purchaseGreenDark,
                        fontWeight: FontWeight.w800,
                      ),
                      SizedBox(
                        width: widths.action,
                        child: Center(
                          child: _PreviewIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'حذف السطر',
                            foreground: _purchaseDanger,
                            background: const Color(0xFFFFF3F3),
                            borderColor: const Color(0xFFF3C8C8),
                            borderRadius: 12,
                            onPressed: onAction,
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
    required this.onAction,
  });

  final VoidCallback onAction;

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
                    SizedBox(width: widths.action),
                  ],
                ),
              ),
              for (var index = 0; index < _previewRows.length; index++)
                Container(
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
                      _GridValueCell(
                        _previewRows[index].code,
                        widths.code,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        fontWeight: FontWeight.w800,
                      ),
                      _GridValueCell(
                        _previewRows[index].name,
                        widths.name,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      _GridValueCell(
                        _previewRows[index].quantity,
                        widths.quantity,
                      ),
                      _GridValueCell(
                        _previewRows[index].price,
                        widths.price,
                        color: _purchaseGreenDark,
                        fontWeight: FontWeight.w800,
                      ),
                      SizedBox(
                        width: widths.action,
                        child: Center(
                          child: _PreviewIconButton(
                            icon: index == _previewRows.length - 1
                                ? Icons.add_rounded
                                : Icons.close_rounded,
                            tooltip: index == _previewRows.length - 1
                                ? 'إضافة مادة'
                                : 'حذف السطر',
                            foreground: index == _previewRows.length - 1
                                ? Colors.white
                                : _purchaseDanger,
                            background: index == _previewRows.length - 1
                                ? _purchaseGreen
                                : Colors.transparent,
                            borderColor: index == _previewRows.length - 1
                                ? _purchaseGreen
                                : const Color(0xFFE7BABA),
                            borderRadius: 999,
                            size: 32,
                            onPressed: onAction,
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
    required this.onAction,
  });

  final VoidCallback onAction;

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
              for (var index = 0; index < _previewRows.length; index++)
                SizedBox(
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
                        text: _previewRows[index].code,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        emphasized: true,
                      ),
                      _SoftDataCell(
                        width: widths.name,
                        text: _previewRows[index].name,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      _SoftDataCell(
                        width: widths.quantity,
                        text: _previewRows[index].quantity,
                      ),
                      _SoftDataCell(
                        width: widths.price,
                        text: _previewRows[index].price,
                        emphasized: true,
                      ),
                      SizedBox(
                        width: widths.action,
                        child: Center(
                          child: _PreviewIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'حذف السطر',
                            foreground: _purchaseDanger,
                            background: Colors.white,
                            borderColor: const Color(0xFFE8C8C8),
                            borderRadius: 13,
                            size: 36,
                            onPressed: onAction,
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
                  label: 'إضافة مادة',
                  icon: Icons.add_rounded,
                  onPressed: onAction,
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
    required this.onAction,
  });

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _PreviewViewport(
      builder: (width) {
        final widths = _PreviewWidths.forWidth(width);

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
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: _purchaseGreen,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '3 مواد جاهزة للمراجعة',
                            style: TextStyle(
                              color: _purchaseGreenDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PreviewWideButton(
                      label: 'إضافة مادة',
                      icon: Icons.add_rounded,
                      compact: true,
                      onPressed: onAction,
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
              for (var index = 0; index < _previewRows.length; index++)
                Container(
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
                        child: Align(
                          alignment: Alignment.centerRight,
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
                            child: Text(
                              _previewRows[index].code,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                color: _purchaseGreenDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _ValueText(
                        _previewRows[index].name,
                        widths.name,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(
                        width: widths.quantity,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 58),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _previewRows[index].quantity,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _ValueText(
                        _previewRows[index].price,
                        widths.price,
                        color: _purchaseGreenDark,
                        fontWeight: FontWeight.w900,
                      ),
                      SizedBox(
                        width: widths.action,
                        child: Center(
                          child: _PreviewIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'حذف السطر',
                            foreground: _purchaseDanger,
                            background: Colors.transparent,
                            borderColor: Colors.transparent,
                            borderRadius: 999,
                            size: 34,
                            onPressed: onAction,
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
                child: const Row(
                  children: [
                    Expanded(
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
                      '1,850,000 د.ع',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
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

class _ValueText extends StatelessWidget {
  const _ValueText(
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
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          textDirection: textDirection,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: fontWeight,
          ),
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
    this.text,
    this.child,
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.emphasized = false,
  }) : assert(text != null || child != null);

  final double width;
  final String? text;
  final Widget? child;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final bool emphasized;

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
              child: Text(
                text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
                textDirection: textDirection,
                style: TextStyle(
                  color: emphasized
                      ? _purchaseGreenDark
                      : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight:
                      emphasized ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
      ),
    );
  }
}

class _PreviewIconButton extends StatelessWidget {
  const _PreviewIconButton({
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
  const _PreviewRow({
    required this.code,
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String code;
  final String name;
  final String quantity;
  final String price;
}

const _previewRows = <_PreviewRow>[
  _PreviewRow(
    code: 'P-001',
    name: 'دفتر ملاحظات',
    quantity: '100',
    price: '2,500',
  ),
  _PreviewRow(
    code: 'P-002',
    name: 'قلم أزرق',
    quantity: '1,000',
    price: '1,250',
  ),
  _PreviewRow(
    code: 'P-003',
    name: 'طابعة مكتبية',
    quantity: '2',
    price: '175,000',
  ),
];
