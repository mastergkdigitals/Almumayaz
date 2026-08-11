import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

final ReportDefinition inventoryReportDefinition = ReportDefinition(
  id: 'inventory',
  title: 'تقرير المخزون والحركة المخزنية',
  icon: Icons.warehouse_rounded,
  palette: AppModulePalettes.warehouses,
  variants: [
    ReportVariantDefinition(
      id: 'currentStock',
      label: 'الرصيد الحالي',
      icon: Icons.inventory_2_rounded,
      filters: _currentStockFilters,
      metrics: _currentStockMetrics,
      columns: _currentStockColumns,
    ),
    ReportVariantDefinition(
      id: 'transfers',
      label: 'سجل النقل المخزني',
      icon: Icons.swap_horiz_rounded,
      filters: _transferFilters,
      metrics: _transferMetrics,
      columns: _transferColumns,
      minimumColumnWidth: 170,
    ),
  ],
);

const List<ReportFilterOption> _inventoryWarehouseOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('main', 'المخزن الرئيسي'),
  ReportFilterOption('karrada', 'مخزن الكرادة'),
  ReportFilterOption('basra', 'مخزن البصرة'),
  ReportFilterOption('erbil', 'مخزن أربيل'),
];

const List<ReportFilterDefinition> _currentStockFilters = [
  ReportFilterDefinition.dropdown(
    id: 'warehouse',
    label: 'المخزن',
    icon: Icons.warehouse_rounded,
    options: _inventoryWarehouseOptions,
  ),
  ReportFilterDefinition.dropdown(
    id: 'product',
    label: 'المادة',
    icon: Icons.inventory_2_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('p1001', 'P-1001 - طابعة ليزر'),
      ReportFilterOption('p1002', 'P-1002 - حبر طابعة أسود'),
      ReportFilterOption('p1003', 'P-1003 - ورق تصوير A4'),
      ReportFilterOption('p1004', 'P-1004 - آلة حاسبة مكتبية'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'group',
    label: 'المجموعة',
    icon: Icons.category_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('officeDevices', 'أجهزة مكتبية'),
      ReportFilterOption('printingSupplies', 'مستلزمات طباعة'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'type',
    label: 'النوع',
    icon: Icons.sell_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('printers', 'طابعات'),
      ReportFilterOption('inks', 'أحبار'),
      ReportFilterOption('printingPaper', 'ورق طباعة'),
      ReportFilterOption('calculators', 'آلات حاسبة'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'stockState',
    label: 'حالة المخزون',
    icon: Icons.inventory_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('available', 'متوفر'),
      ReportFilterOption('out', 'نافد'),
    ],
  ),
];

const List<ReportMetricDefinition> _currentStockMetrics = [
  ReportMetricDefinition(label: 'المواد المختلفة'),
  ReportMetricDefinition(label: 'المخازن'),
  ReportMetricDefinition(label: 'الأرصدة الموجبة'),
  ReportMetricDefinition(label: 'مجموع الكميات'),
];

const List<ReportColumnDefinition> _currentStockColumns = [
  ReportColumnDefinition(label: 'ت', numeric: true, flex: 0.5),
  ReportColumnDefinition(label: 'رمز المادة', numeric: true),
  ReportColumnDefinition(label: 'اسم المادة', flex: 1.5),
  ReportColumnDefinition(label: 'المجموعة', flex: 1.3),
  ReportColumnDefinition(label: 'النوع'),
  ReportColumnDefinition(label: 'المخزن', flex: 1.3),
  ReportColumnDefinition(label: 'الكمية', numeric: true),
];

const List<ReportFilterDefinition> _transferFilters = [
  ReportFilterDefinition.dateRange(id: 'period', label: 'الفترة'),
  ReportFilterDefinition.dropdown(
    id: 'sourceWarehouse',
    label: 'من مخزن',
    icon: Icons.warehouse_outlined,
    options: _inventoryWarehouseOptions,
  ),
  ReportFilterDefinition.dropdown(
    id: 'destinationWarehouse',
    label: 'إلى مخزن',
    icon: Icons.warehouse_rounded,
    options: _inventoryWarehouseOptions,
  ),
  ReportFilterDefinition.dropdown(
    id: 'product',
    label: 'المادة',
    icon: Icons.inventory_2_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('paperA4', 'ورق تصوير A4'),
      ReportFilterOption('blackInk', 'حبر طابعة أسود'),
      ReportFilterOption('calculator', 'آلة حاسبة مكتبية'),
    ],
  ),
];

const List<ReportMetricDefinition> _transferMetrics = [
  ReportMetricDefinition(label: 'عدد عمليات النقل'),
  ReportMetricDefinition(label: 'عدد سطور المواد'),
  ReportMetricDefinition(label: 'مجموع الكميات'),
];

const List<ReportColumnDefinition> _transferColumns = [
  ReportColumnDefinition(label: 'ت', numeric: true, flex: 0.5),
  ReportColumnDefinition(label: 'رقم النقل', numeric: true),
  ReportColumnDefinition(label: 'التاريخ', numeric: true),
  ReportColumnDefinition(label: 'من مخزن', flex: 1.3),
  ReportColumnDefinition(label: 'إلى مخزن', flex: 1.3),
  ReportColumnDefinition(label: 'المواد', flex: 3),
];
