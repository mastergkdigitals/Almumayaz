import 'package:flutter/foundation.dart';

import '../domain/cashbox_voucher.dart';

@immutable
class CashboxState {
  const CashboxState({
    required this.vouchers,
    this.query = '',
    this.selectedVoucherId,
  });

  final List<CashboxVoucher> vouchers;
  final String query;
  final String? selectedVoucherId;

  CashboxState copyWith({
    List<CashboxVoucher>? vouchers,
    String? query,
    Object? selectedVoucherId = _unchanged,
  }) {
    return CashboxState(
      vouchers: vouchers ?? this.vouchers,
      query: query ?? this.query,
      selectedVoucherId: identical(selectedVoucherId, _unchanged)
          ? this.selectedVoucherId
          : selectedVoucherId as String?,
    );
  }
}

const _unchanged = Object();

class CashboxController extends ChangeNotifier {
  CashboxController({List<CashboxVoucher>? initialVouchers})
      : _state = CashboxState(
          vouchers: List.unmodifiable(initialVouchers ?? _demoVouchers),
        );

  static const openingBalanceIqd = 9_800_000;
  static const openingBalanceUsd = 4_500;

  CashboxState _state;

  CashboxState get state => _state;

  List<CashboxVoucher> get visibleVouchers {
    final query =
        _state.query.trim().toLowerCase().replaceAll(',', '');
    if (query.isEmpty) return _state.vouchers;
    return List.unmodifiable(
      _state.vouchers.where(
        (voucher) =>
            voucher.searchText.replaceAll(',', '').contains(query),
      ),
    );
  }

  CashboxVoucher? get selectedVoucher {
    final selectedId = _state.selectedVoucherId;
    if (selectedId == null) return null;
    for (final voucher in _state.vouchers) {
      if (voucher.id == selectedId) return voucher;
    }
    return null;
  }

  int get nextNumber {
    if (_state.vouchers.isEmpty) return 1;
    return _state.vouchers
            .map((voucher) => voucher.number)
            .reduce((first, second) => first > second ? first : second) +
        1;
  }

  CashboxSummary get summary {
    num receiptIqd = 0;
    num paymentIqd = 0;
    num receiptUsd = 0;
    num paymentUsd = 0;
    num balanceIqd = openingBalanceIqd;
    num balanceUsd = openingBalanceUsd;
    final today = DateTime.now();

    for (final voucher in _state.vouchers) {
      final sign =
          voucher.type == CashboxVoucherType.receipt ? 1 : -1;
      balanceIqd += voucher.amountIqd * sign;
      balanceUsd += voucher.amountUsd * sign;

      final isToday = voucher.createdAt.year == today.year &&
          voucher.createdAt.month == today.month &&
          voucher.createdAt.day == today.day;
      if (!isToday) continue;

      if (voucher.type == CashboxVoucherType.receipt) {
        receiptIqd += voucher.amountIqd;
        receiptUsd += voucher.amountUsd;
      } else {
        paymentIqd += voucher.amountIqd;
        paymentUsd += voucher.amountUsd;
      }
    }

    return CashboxSummary(
      balanceIqd: balanceIqd,
      balanceUsd: balanceUsd,
      todayReceiptIqd: receiptIqd,
      todayPaymentIqd: paymentIqd,
      todayReceiptUsd: receiptUsd,
      todayPaymentUsd: paymentUsd,
    );
  }

  int get selectedVisibleIndex =>
      _selectedVisibleIndex(visibleVouchers);

  void search(String value) {
    if (_state.query == value) return;
    _state = _state.copyWith(query: value);
    notifyListeners();
  }

  void select(String? voucherId) {
    if (_state.selectedVoucherId == voucherId) return;
    _state = _state.copyWith(selectedVoucherId: voucherId);
    notifyListeners();
  }

  void first() => _selectAt(0);

  void previous() {
    final vouchers = visibleVouchers;
    if (vouchers.isEmpty) return;
    final index = _selectedVisibleIndex(vouchers);
    if (index < 0) {
      _selectAt(vouchers.length - 1);
      return;
    }
    _selectAt(index <= 0 ? 0 : index - 1);
  }

  void next() {
    final vouchers = visibleVouchers;
    if (vouchers.isEmpty) {
      select(null);
      return;
    }
    final index = _selectedVisibleIndex(vouchers);
    if (index < 0) {
      _selectAt(0);
      return;
    }
    if (index >= vouchers.length - 1) {
      select(null);
      return;
    }
    _selectAt(index + 1);
  }

  void last() {
    final vouchers = visibleVouchers;
    if (vouchers.isEmpty) {
      select(null);
      return;
    }
    final index = _selectedVisibleIndex(vouchers);
    if (index == vouchers.length - 1) {
      select(null);
      return;
    }
    _selectAt(vouchers.length - 1);
  }

  void add(CashboxVoucher voucher) {
    _state = _state.copyWith(
      vouchers: List.unmodifiable([..._state.vouchers, voucher]),
      selectedVoucherId: voucher.id,
    );
    notifyListeners();
  }

  void update(CashboxVoucher voucher) {
    final index =
        _state.vouchers.indexWhere((item) => item.id == voucher.id);
    if (index < 0) return;
    final updated = [..._state.vouchers]..[index] = voucher;
    _state = _state.copyWith(vouchers: List.unmodifiable(updated));
    notifyListeners();
  }

  CashboxVoucher? deleteSelected() {
    final selected = selectedVoucher;
    if (selected == null) return null;
    _state = _state.copyWith(
      vouchers: List.unmodifiable(
        _state.vouchers.where((voucher) => voucher.id != selected.id),
      ),
      selectedVoucherId: null,
    );
    notifyListeners();
    return selected;
  }

  void _selectAt(int index) {
    final vouchers = visibleVouchers;
    if (vouchers.isEmpty || index < 0 || index >= vouchers.length) return;
    select(vouchers[index].id);
  }

  int _selectedVisibleIndex(List<CashboxVoucher> vouchers) {
    return vouchers.indexWhere(
      (voucher) => voucher.id == _state.selectedVoucherId,
    );
  }
}

final _demoVouchers = <CashboxVoucher>[
  CashboxVoucher(
    id: 'cashbox-001',
    number: 1,
    createdAt: DateTime(2026, 7, 27, 8, 30),
    type: CashboxVoucherType.receipt,
    mainAccountId: 'parties',
    mainAccountLabel: 'الأطراف',
    subaccountId: 'party-nakheel',
    subaccountLabel: '1 - شركة النخيل للتجارة',
    exchangeRate: 1310,
    amountIqd: 750000,
    amountUsd: 0,
    balanceBeforeIqd: 1250000,
    balanceAfterIqd: 500000,
    balanceBeforeUsd: 850,
    balanceAfterUsd: 850,
    notes: 'دفعة على الحساب',
  ),
  CashboxVoucher(
    id: 'cashbox-002',
    number: 2,
    createdAt: DateTime(2026, 7, 27, 9, 10),
    type: CashboxVoucherType.payment,
    mainAccountId: 'expenses',
    mainAccountLabel: 'المصاريف',
    subaccountId: 'expense-transport',
    subaccountLabel: 'نقل',
    exchangeRate: 1310,
    amountIqd: 125000,
    amountUsd: 0,
    balanceBeforeIqd: 0,
    balanceAfterIqd: 125000,
    balanceBeforeUsd: 0,
    balanceAfterUsd: 0,
    notes: 'نقل مواد إلى المخزن',
  ),
  CashboxVoucher(
    id: 'cashbox-003',
    number: 3,
    createdAt: DateTime(2026, 7, 27, 10, 5),
    type: CashboxVoucherType.payment,
    mainAccountId: 'parties',
    mainAccountLabel: 'الأطراف',
    subaccountId: 'party-rafidain',
    subaccountLabel: '3 - مجهز الرافدين',
    exchangeRate: 1310,
    amountIqd: 0,
    amountUsd: 400,
    balanceBeforeIqd: -3200000,
    balanceAfterIqd: -3200000,
    balanceBeforeUsd: -1200,
    balanceAfterUsd: -800,
    notes: 'تسديد جزء من الرصيد',
  ),
  CashboxVoucher(
    id: 'cashbox-004',
    number: 4,
    createdAt: DateTime(2026, 7, 26, 11, 40),
    type: CashboxVoucherType.receipt,
    mainAccountId: 'other-income',
    mainAccountLabel: 'إيرادات أخرى',
    subaccountId: 'income-services',
    subaccountLabel: 'خدمات',
    exchangeRate: 1310,
    amountIqd: 300000,
    amountUsd: 0,
    balanceBeforeIqd: 0,
    balanceAfterIqd: -300000,
    balanceBeforeUsd: 0,
    balanceAfterUsd: 0,
    notes: '',
  ),
  CashboxVoucher(
    id: 'cashbox-005',
    number: 5,
    createdAt: DateTime(2026, 7, 25, 13, 15),
    type: CashboxVoucherType.payment,
    mainAccountId: 'expenses',
    mainAccountLabel: 'المصاريف',
    subaccountId: 'expense-maintenance',
    subaccountLabel: 'صيانة',
    exchangeRate: 1310,
    amountIqd: 85000,
    amountUsd: 0,
    balanceBeforeIqd: 125000,
    balanceAfterIqd: 210000,
    balanceBeforeUsd: 0,
    balanceAfterUsd: 0,
    notes: 'صيانة أجهزة المكتب',
  ),
  CashboxVoucher(
    id: 'cashbox-006',
    number: 6,
    createdAt: DateTime(2026, 7, 24, 15, 20),
    type: CashboxVoucherType.receipt,
    mainAccountId: 'parties',
    mainAccountLabel: 'الأطراف',
    subaccountId: 'party-ahmed',
    subaccountLabel: '2 - أحمد كريم',
    exchangeRate: 1310,
    amountIqd: 475000,
    amountUsd: 0,
    balanceBeforeIqd: 475000,
    balanceAfterIqd: 0,
    balanceBeforeUsd: 0,
    balanceAfterUsd: 0,
    notes: 'تسديد كامل الرصيد',
  ),
];
