import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../presentation/report_definition.dart';

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

final List<ReportRowDefinition> currentStockDemoRows =
    List<ReportRowDefinition>.unmodifiable([
  ReportRowDefinition(
    id: 'stock-p1001-main',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'main',
      'product': 'p1001',
      'group': 'officeDevices',
      'type': 'printers',
      'stockState': 'available',
    },
    cells: const [
      '1',
      'P-1001',
      'طابعة ليزر',
      'أجهزة مكتبية',
      'طابعات',
      'المخزن الرئيسي',
      '18',
    ],
  ),
  ReportRowDefinition(
    id: 'stock-p1002-main',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'main',
      'product': 'p1002',
      'group': 'printingSupplies',
      'type': 'inks',
      'stockState': 'available',
    },
    cells: const [
      '2',
      'P-1002',
      'حبر طابعة أسود',
      'مستلزمات طباعة',
      'أحبار',
      'المخزن الرئيسي',
      '64',
    ],
  ),
  ReportRowDefinition(
    id: 'stock-p1003-main',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'main',
      'product': 'p1003',
      'group': 'printingSupplies',
      'type': 'printingPaper',
      'stockState': 'available',
    },
    cells: const [
      '3',
      'P-1003',
      'ورق تصوير A4',
      'مستلزمات طباعة',
      'ورق طباعة',
      'المخزن الرئيسي',
      '120',
    ],
  ),
  ReportRowDefinition(
    id: 'stock-p1004-main',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'main',
      'product': 'p1004',
      'group': 'officeDevices',
      'type': 'calculators',
      'stockState': 'available',
    },
    cells: const [
      '4',
      'P-1004',
      'آلة حاسبة مكتبية',
      'أجهزة مكتبية',
      'آلات حاسبة',
      'المخزن الرئيسي',
      '25',
    ],
  ),
  ReportRowDefinition(
    id: 'stock-p1001-karrada',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'karrada',
      'product': 'p1001',
      'group': 'officeDevices',
      'type': 'printers',
      'stockState': 'available',
    },
    cells: const [
      '5',
      'P-1001',
      'طابعة ليزر',
      'أجهزة مكتبية',
      'طابعات',
      'مخزن الكرادة',
      '7',
    ],
  ),
  ReportRowDefinition(
    id: 'stock-p1003-karrada',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'karrada',
      'product': 'p1003',
      'group': 'printingSupplies',
      'type': 'printingPaper',
      'stockState': 'available',
    },
    cells: const [
      '6',
      'P-1003',
      'ورق تصوير A4',
      'مستلزمات طباعة',
      'ورق طباعة',
      'مخزن الكرادة',
      '45',
    ],
  ),
  ReportRowDefinition(
    id: 'stock-p1002-basra',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'basra',
      'product': 'p1002',
      'group': 'printingSupplies',
      'type': 'inks',
      'stockState': 'available',
    },
    cells: const [
      '7',
      'P-1002',
      'حبر طابعة أسود',
      'مستلزمات طباعة',
      'أحبار',
      'مخزن البصرة',
      '22',
    ],
  ),
  ReportRowDefinition(
    id: 'stock-p1004-basra',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'basra',
      'product': 'p1004',
      'group': 'officeDevices',
      'type': 'calculators',
      'stockState': 'available',
    },
    cells: const [
      '8',
      'P-1004',
      'آلة حاسبة مكتبية',
      'أجهزة مكتبية',
      'آلات حاسبة',
      'مخزن البصرة',
      '11',
    ],
  ),
  ReportRowDefinition(
    id: 'stock-p1003-erbil',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'erbil',
      'product': 'p1003',
      'group': 'printingSupplies',
      'type': 'printingPaper',
      'stockState': 'available',
    },
    cells: const [
      '9',
      'P-1003',
      'ورق تصوير A4',
      'مستلزمات طباعة',
      'ورق طباعة',
      'مخزن أربيل',
      '32',
    ],
  ),
]);

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

final List<ReportRowDefinition> transferDemoRows =
    List<ReportRowDefinition>.unmodifiable([
  ReportRowDefinition(
    id: 'transfer-104',
    date: DateTime(2026, 7, 24),
    filterValues: const {
      'sourceWarehouse': 'main',
      'destinationWarehouse': 'karrada',
      'product': 'paperA4',
    },
    cells: const [
      '1',
      '104',
      '2026/07/24',
      'المخزن الرئيسي',
      'مخزن الكرادة',
      'P-1003 - ورق تصوير A4 (20)',
    ],
  ),
  ReportRowDefinition(
    id: 'transfer-103',
    date: DateTime(2026, 7, 22),
    filterValues: const {
      'sourceWarehouse': 'basra',
      'destinationWarehouse': 'main',
      'product': 'blackInk|calculator',
    },
    searchTerms: const ['آلة حاسبة مكتبية', 'P-1004'],
    cells: const [
      '2',
      '103',
      '2026/07/22',
      'مخزن البصرة',
      'المخزن الرئيسي',
      'P-1002 - حبر طابعة أسود (5)، P-1004 - آلة حاسبة مكتبية (2)',
    ],
  ),
]);
