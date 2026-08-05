import 'package:flutter/foundation.dart';

import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../settings/domain/settings_models.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/cashbox_repository.dart';
import '../domain/cashbox_voucher.dart';

@immutable
class CashboxState {
  const CashboxState({
    this.dataState = const AppDataState.loading(),
    this.accounts = const [],
    this.openingBalance = const CashboxBalanceSnapshot(
      iqd: Money.fromMinorUnits(0, AppCurrency.iqd),
      usd: Money.fromMinorUnits(0, AppCurrency.usd),
    ),
    this.defaultVoucherType = CashboxVoucherType.receipt,
    this.defaultMainAccountId,
    this.defaultExchangeRate = 1310,
    this.query = '',
    this.selectedVoucherId,
  });

  final AppDataState<List<CashboxVoucher>> dataState;
  final List<CashboxMainAccount> accounts;
  final CashboxBalanceSnapshot openingBalance;
  final CashboxVoucherType defaultVoucherType;
  final String? defaultMainAccountId;
  final num defaultExchangeRate;
  final String query;
  final String? selectedVoucherId;

  List<CashboxVoucher> get vouchers => dataState.data ?? const [];

  CashboxState copyWith({
    AppDataState<List<CashboxVoucher>>? dataState,
    List<CashboxMainAccount>? accounts,
    CashboxBalanceSnapshot? openingBalance,
    CashboxVoucherType? defaultVoucherType,
    Object? defaultMainAccountId = _unchanged,
    num? defaultExchangeRate,
    String? query,
    Object? selectedVoucherId = _unchanged,
  }) {
    return CashboxState(
      dataState: dataState ?? this.dataState,
      accounts: accounts ?? this.accounts,
      openingBalance: openingBalance ?? this.openingBalance,
      defaultVoucherType: defaultVoucherType ?? this.defaultVoucherType,
      defaultMainAccountId: identical(defaultMainAccountId, _unchanged)
          ? this.defaultMainAccountId
          : defaultMainAccountId as String?,
      defaultExchangeRate: defaultExchangeRate ?? this.defaultExchangeRate,
      query: query ?? this.query,
      selectedVoucherId: identical(selectedVoucherId, _unchanged)
          ? this.selectedVoucherId
          : selectedVoucherId as String?,
    );
  }
}

const _unchanged = Object();

class CashboxController extends ChangeNotifier {
  CashboxController({
    required CashboxRepository repository,
    required BusinessSettingsRepository settingsRepository,
    VoidCallback? onDataChanged,
  })  : _repository = repository,
        _settingsRepository = settingsRepository,
        _onDataChanged = onDataChanged;

  final CashboxRepository _repository;
  final BusinessSettingsRepository _settingsRepository;
  final VoidCallback? _onDataChanged;
  CashboxState _state = const CashboxState();
  bool _isDisposed = false;
  int _loadGeneration = 0;

  CashboxState get state => _state;

  List<CashboxVoucher> get visibleVouchers {
    final query = _state.query.trim().toLowerCase().replaceAll(',', '');
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
    num balanceIqd = _state.openingBalance.iqd.majorUnits;
    num balanceUsd = _state.openingBalance.usd.majorUnits;
    final summaryDay = _latestActivityDay;

    for (final voucher in _state.vouchers) {
      final sign = voucher.type == CashboxVoucherType.receipt ? 1 : -1;
      balanceIqd += voucher.amountIqd * sign;
      balanceUsd += voucher.amountUsd * sign;
      final isToday = summaryDay != null &&
          voucher.createdAt.year == summaryDay.year &&
          voucher.createdAt.month == summaryDay.month &&
          voucher.createdAt.day == summaryDay.day;
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

  DateTime? get _latestActivityDay {
    DateTime? latest;
    for (final voucher in _state.vouchers) {
      if (latest == null || voucher.createdAt.isAfter(latest)) {
        latest = voucher.createdAt;
      }
    }
    return latest;
  }

  CashboxAccountBalance accountBalance(
    String subaccountId, {
    CashboxAccountBalance fallback = const CashboxAccountBalance(
      iqd: 0,
      usd: 0,
    ),
  }) {
    CashboxVoucher? latest;
    for (final voucher in _state.vouchers) {
      if (voucher.subaccountId != subaccountId) continue;
      if (latest == null || _comesBefore(latest, voucher)) latest = voucher;
    }
    if (latest != null) {
      return CashboxAccountBalance(
        iqd: latest.balanceAfterIqd,
        usd: latest.balanceAfterUsd,
      );
    }
    for (final main in _state.accounts) {
      for (final subaccount in main.subaccounts) {
        if (subaccount.id == subaccountId) {
          return CashboxAccountBalance(
            iqd: subaccount.balanceIqd,
            usd: subaccount.balanceUsd,
          );
        }
      }
    }
    return fallback;
  }

  int get selectedVisibleIndex => _selectedVisibleIndex(visibleVouchers);

  Future<void> load() async {
    if (_isDisposed) return;
    final generation = ++_loadGeneration;
    _state = _state.copyWith(dataState: const AppDataState.loading());
    _notifyListenersIfActive();
    try {
      final vouchers = await _repository.getAll();
      final accounts = await _repository.getMainAccounts();
      final openingBalance = await _repository.getOpeningBalance();
      final defaults = await _settingsRepository.loadOperationalDefaults();
      final policies = await _settingsRepository.loadBusinessPolicies();
      if (_loadIsStale(generation)) return;

      final accountsById = {
        for (final account in accounts) account.id: account,
      };
      final defaultAccount = accountsById[defaults.cashbox.mainAccountId.value];
      if (accounts.isEmpty ||
          defaultAccount == null ||
          defaultAccount.subaccounts.isEmpty) {
        _setMissingReference(
          'حساب الصندوق الافتراضي أو حساباته الفرعية غير متاحة',
          generation,
        );
        return;
      }

      final resolved = <CashboxVoucher>[];
      for (final voucher in vouchers) {
        final main = accountsById[voucher.mainAccountId];
        CashboxSubaccount? subaccount;
        if (main != null) {
          for (final candidate in main.subaccounts) {
            if (candidate.id == voucher.subaccountId) {
              subaccount = candidate;
              break;
            }
          }
        }
        if (main == null || subaccount == null) {
          _setMissingReference(
            'تعذر العثور على حساب مرتبط بسند الصندوق رقم '
            '${voucher.number}',
            generation,
          );
          return;
        }
        resolved.add(
          voucher.copyWith(
            mainAccountLabel: main.label,
            subaccountLabel: subaccount.label,
          ),
        );
      }

      _state = _state.copyWith(
        dataState: resolved.isEmpty
            ? const AppDataState.empty(
                message: 'لا توجد سندات صندوق مسجلة حالياً.',
              )
            : AppDataState.ready(List.unmodifiable(resolved)),
        accounts: List.unmodifiable(accounts),
        openingBalance: openingBalance,
        defaultVoucherType:
            defaults.cashbox.movementKind == CashboxMovementKind.receipt
                ? CashboxVoucherType.receipt
                : CashboxVoucherType.payment,
        defaultMainAccountId: defaultAccount.id,
        defaultExchangeRate: policies.defaultExchangeRate.value,
        selectedVoucherId: resolved.any(
          (voucher) => voucher.id == _state.selectedVoucherId,
        )
            ? _state.selectedVoucherId
            : null,
      );
      _notifyListenersIfActive();
    } catch (error) {
      if (_loadIsStale(generation)) return;
      _state = _state.copyWith(
        dataState: AppDataState.error(
          error,
          message: 'تعذر تحميل بيانات الصندوق.',
        ),
      );
      _notifyListenersIfActive();
    }
  }

  void search(String value) {
    if (_isDisposed || _state.query == value) return;
    _state = _state.copyWith(query: value);
    _notifyListenersIfActive();
  }

  void select(String? voucherId) {
    if (_isDisposed || _state.selectedVoucherId == voucherId) return;
    _state = _state.copyWith(selectedVoucherId: voucherId);
    _notifyListenersIfActive();
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

  Future<CashboxVoucher> add(CashboxVoucher voucher) async {
    final saved = await _repository.save(voucher);
    if (_isDisposed) return saved;
    await load();
    if (_isDisposed) return saved;
    select(saved.id);
    _onDataChanged?.call();
    return selectedVoucher ?? saved;
  }

  Future<CashboxVoucher> update(CashboxVoucher voucher) async {
    final saved = await _repository.save(voucher);
    if (_isDisposed) return saved;
    await load();
    if (_isDisposed) return saved;
    select(saved.id);
    _onDataChanged?.call();
    return selectedVoucher ?? saved;
  }

  Future<DeleteDecision> canDeleteSelected() async {
    final selected = selectedVoucher;
    if (selected == null) {
      return const DeleteDecision.blocked('اختر سنداً من الجدول لحذفه');
    }
    return _repository.canDelete(selected.entityId);
  }

  Future<CashboxVoucher?> deleteSelected() async {
    final selected = selectedVoucher;
    if (selected == null) return null;
    final decision = await _repository.canDelete(selected.entityId);
    if (!decision.isAllowed) return null;
    await _repository.delete(selected.entityId);
    if (_isDisposed) return selected;
    await load();
    if (_isDisposed) return selected;
    _onDataChanged?.call();
    return selected;
  }

  void _setMissingReference(String message, int generation) {
    if (_loadIsStale(generation)) return;
    _state = _state.copyWith(
      dataState: AppDataState.missingReference(message),
    );
    _notifyListenersIfActive();
  }

  bool _loadIsStale(int generation) {
    return _isDisposed || generation != _loadGeneration;
  }

  void _notifyListenersIfActive() {
    if (!_isDisposed) notifyListeners();
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

  static int _compareVouchers(
    CashboxVoucher first,
    CashboxVoucher second,
  ) {
    final byDate = first.createdAt.compareTo(second.createdAt);
    if (byDate != 0) return byDate;
    return first.number.compareTo(second.number);
  }

  static bool _comesBefore(
    CashboxVoucher first,
    CashboxVoucher second,
  ) =>
      _compareVouchers(first, second) < 0;

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration++;
    super.dispose();
  }
}
