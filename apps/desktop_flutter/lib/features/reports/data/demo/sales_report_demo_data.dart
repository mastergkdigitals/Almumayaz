import '../../domain/report_models.dart';

final List<ReportRowDefinition> salesInvoiceDemoRows =
    List<ReportRowDefinition>.unmodifiable([
  ReportRowDefinition(
    id: 'sales-103',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'main',
      'customer': 'dijla',
      'saleType': 'cash',
      'currency': 'IQD',
    },
    cells: const [
      '1',
      '103',
      '2026/07/27',
      'أسواق دجلة',
      'الرئيسي',
      'نقدي',
      'دينار',
      '310,000',
      '310,000',
      '0',
      '3',
    ],
  ),
  ReportRowDefinition(
    id: 'sales-102',
    date: DateTime(2026, 7, 26, 15, 30),
    filterValues: const {
      'warehouse': 'mansour',
      'customer': 'ahmed',
      'saleType': 'installments',
      'currency': 'USD',
    },
    cells: const [
      '2',
      '102',
      '2026/07/26',
      'أحمد كريم',
      'المنصور',
      'أقساط',
      'دولار',
      '1,250.00',
      '250.00',
      '1,000.00',
      '2',
    ],
  ),
  ReportRowDefinition(
    id: 'sales-101',
    date: DateTime(2026, 7, 25),
    filterValues: const {
      'warehouse': 'rasafa',
      'customer': 'nakheel',
      'saleType': 'credit',
      'currency': 'IQD',
    },
    cells: const [
      '3',
      '101',
      '2026/07/25',
      'شركة النخيل للتجارة',
      'الرصافة',
      'آجل',
      'دينار',
      '177,000',
      '0',
      '177,000',
      '3',
    ],
  ),
]);
