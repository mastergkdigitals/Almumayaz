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
    this.defaultMainAccountEntityId,
    this.defaultExchangeRateValue =
        const ExchangeRate.fromTenThousandths(13100000),
    this.query = '',
    this.selectedVoucherEntityId,
  });

  final AppDataState<List<CashboxVoucher>> dataState;
  final List<CashboxMainAccount> accounts;
  final CashboxBalanceSnapshot openingBalance;
  final CashboxVoucherType defaultVoucherType;
  final EntityId? defaultMainAccountEntityId;
  final ExchangeRate defaultExchangeRateValue;
  final String query;
  final EntityId? selectedVoucherEntityId;

  String? get defaultMainAccountId => defaultMainAccountEntityId?.value;
  num get defaultExchangeRate => defaultExchangeRateValue.value;
  String? get selectedVoucherId => selectedVoucherEntityId?.value;

  List<CashboxVoucher> get vouchers => dataState.data ?? const [];

  CashboxState copyWith({
    AppDataState<List<CashboxVoucher>>? dataState,
    List<CashboxMainAccount>? accounts,
    CashboxBalanceSnapshot? openingBalance,
    CashboxVoucherType? defaultVoucherType,
    Object? defaultMainAccountEntityId = _unchanged,
    ExchangeRate? defaultExchangeRateValue,
    String? query,
    Object? selectedVoucherEntityId = _unchanged,
  }) {
    return CashboxState(
      dataState: dataState ?? this.dataState,
      accounts: accounts ?? this.accounts,
      openingBalance: openingBalance ?? this.openingBalance,
      defaultVoucherType: defaultVoucherType ?? this.defaultVoucherType,
      defaultMainAccountEntityId:
          identical(defaultMainAccountEntityId, _unchanged)
              ? this.defaultMainAccountEntityId
              : defaultMainAccountEntityId as EntityId?,
      defaultExchangeRateValue:
          defaultExchangeRateValue ?? this.defaultExchangeRateValue,
      query: query ?? this.query,
      selectedVoucherEntityId:
          identical(selectedVoucherEntityId, _unchanged)
              ? this.selectedVoucherEntityId
              : selectedVoucherEntityId as EntityId?,
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
  int _nextVoucherNumber = 1;

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
    final selectedId = _state.selectedVoucherEntityId;
    if (selectedId == null) return null;
    for (final voucher in _state.vouchers) {
      if (voucher.entityId == selectedId) return voucher;
    }
    return null;
  }

  int get nextNumber => _nextVoucherNumber;

  CashboxSummary get summary {
    var receiptIqd = Money.zero(AppCurrency.iqd);
    var paymentIqd = Money.zero(AppCurrency.iqd);
    var receiptUsd = Money.zero(AppCurrency.usd);
    var paymentUsd = Money.zero(AppCurrency.usd);
    var balanceIqd = _state.openingBalance.iqd;
    var balanceUsd = _state.openingBalance.usd;
    final summaryDay = _latestActivityDay;

    for (final voucher in _state.vouchers) {
      final sign = voucher.type == CashboxVoucherType.receipt ? 1 : -1;
      balanceIqd += voucher.iqdAmount * sign;
      balanceUsd += voucher.usdAmount * sign;
      final isToday = summaryDay != null &&
          voucher.createdTimestamp.localDate == summaryDay;
      if (!isToday) continue;
      if (voucher.type == CashboxVoucherType.receipt) {
        receiptIqd += voucher.iqdAmount;
        receiptUsd += voucher.usdAmount;
      } else {
        paymentIqd += voucher.iqdAmount;
        paymentUsd += voucher.usdAmount;
      }
    }

    return CashboxSummary.typed(
      iqdBalance: balanceIqd,
      usdBalance: balanceUsd,
      iqdTodayReceipt: receiptIqd,
      iqdTodayPayment: paymentIqd,
      usdTodayReceipt: receiptUsd,
      usdTodayPayment: paymentUsd,
    );
  }

  BusinessDate? get _latestActivityDay {
    AuditTimestamp? latest;
    for (final voucher in _state.vouchers) {
      if (latest == null || voucher.createdTimestamp.compareTo(latest) > 0) {
        latest = voucher.createdTimestamp;
      }
    }
    return latest?.localDate;
  }

  CashboxAccountBalance accountBalance(
    String subaccountId, {
    CashboxAccountBalance? fallback,
  }) {
    CashboxVoucher? latest;
    for (final voucher in _state.vouchers) {
      if (voucher.subaccountId != subaccountId) continue;
      if (latest == null || _comesBefore(latest, voucher)) latest = voucher;
    }
    if (latest != null) {
      return CashboxAccountBalance.typed(
        iqdMoney: latest.iqdBalanceAfter,
        usdMoney: latest.usdBalanceAfter,
      );
    }
    for (final main in _state.accounts) {
      for (final subaccount in main.subaccounts) {
        if (subaccount.id == subaccountId) {
          return CashboxAccountBalance.typed(
            iqdMoney: subaccount.iqdBalance,
            usdMoney: subaccount.usdBalance,
          );
        }
      }
    }
    return fallback ??
        CashboxAccountBalance.typed(
          iqdMoney: Money.zero(AppCurrency.iqd),
          usdMoney: Money.zero(AppCurrency.usd),
        );
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
      final repository = _repository;
      final nextVoucherNumber = repository is CashboxIssuedNumberRepository
          ? await repository.nextVoucherNumber()
          : _nextNumberFrom(vouchers);
      final defaults = await _settingsRepository.loadOperationalDefaults();
      final policies = await _settingsRepository.loadBusinessPolicies();
      if (_loadIsStale(generation)) return;

      final accountsById = {
        for (final account in accounts) account.entityId: account,
      };
      final defaultAccount = accountsById[defaults.cashbox.mainAccountId];
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
        final main = accountsById[voucher.mainAccountEntityId];
        CashboxSubaccount? subaccount;
        if (main != null) {
          for (final candidate in main.subaccounts) {
            if (candidate.entityId == voucher.subaccountEntityId) {
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
        defaultMainAccountEntityId: defaultAccount.entityId,
        defaultExchangeRateValue: policies.defaultExchangeRate,
        selectedVoucherEntityId: resolved.any(
          (voucher) => voucher.entityId == _state.selectedVoucherEntityId,
        )
            ? _state.selectedVoucherEntityId
            : null,
      );
      _nextVoucherNumber = nextVoucherNumber;
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
    if (_isDisposed) return;
    final entityId = voucherId == null ? null : EntityId(voucherId);
    if (_state.selectedVoucherEntityId == entityId) return;
    _state = _state.copyWith(selectedVoucherEntityId: entityId);
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
    select(vouchers[index].entityId.value);
  }

  int _selectedVisibleIndex(List<CashboxVoucher> vouchers) {
    return vouchers.indexWhere(
      (voucher) => voucher.entityId == _state.selectedVoucherEntityId,
    );
  }

  static int _compareVouchers(
    CashboxVoucher first,
    CashboxVoucher second,
  ) {
    final byDate =
        first.createdTimestamp.compareTo(second.createdTimestamp);
    if (byDate != 0) return byDate;
    return first.number.compareTo(second.number);
  }

  static bool _comesBefore(
    CashboxVoucher first,
    CashboxVoucher second,
  ) =>
      _compareVouchers(first, second) < 0;

  static int _nextNumberFrom(Iterable<CashboxVoucher> vouchers) {
    var highest = 0;
    for (final voucher in vouchers) {
      if (voucher.number > highest) highest = voucher.number;
    }
    return highest + 1;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration++;
    super.dispose();
  }
}
