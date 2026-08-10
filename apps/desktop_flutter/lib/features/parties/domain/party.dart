import '../../../core/domain/business_values.dart';

enum PartyType {
  customer('زبون'),
  supplier('مجهز'),
  employee('موظف'),
  customerAndSupplier('زبون ومجهز');

  const PartyType(this.label);

  final String label;
}

/// A party persisted with stable identity, exact money and an audit timestamp.
///
/// The default factory keeps the current presentation API source-compatible.
/// Repositories and data adapters should prefer [Party.typed].
class Party {
  factory Party({
    required String id,
    required int number,
    required DateTime createdAt,
    required String name,
    required PartyType type,
    required String workplace,
    required String branch,
    required String phone,
    required String alternatePhone,
    required String city,
    required String address,
    required String notes,
    required num balanceIqd,
    required num balanceUsd,
  }) {
    return Party.typed(
      entityId: EntityId(id),
      number: number,
      createdTimestamp: AuditTimestamp(createdAt),
      name: name,
      type: type,
      workplace: workplace,
      branch: branch,
      phone: phone,
      alternatePhone: alternatePhone,
      city: city,
      address: address,
      notes: notes,
      iqdBalance: Money.fromMajor(balanceIqd, AppCurrency.iqd),
      usdBalance: Money.fromMajor(balanceUsd, AppCurrency.usd),
    );
  }

  Party.typed({
    required this.entityId,
    required this.number,
    required this.createdTimestamp,
    required this.name,
    required this.type,
    required this.workplace,
    required this.branch,
    required this.phone,
    required this.alternatePhone,
    required this.city,
    required this.address,
    required this.notes,
    required this.iqdBalance,
    required this.usdBalance,
  }) {
    _requireCurrency(iqdBalance, AppCurrency.iqd, 'iqdBalance');
    _requireCurrency(usdBalance, AppCurrency.usd, 'usdBalance');
  }

  final EntityId entityId;
  final int number;
  final AuditTimestamp createdTimestamp;
  final String name;
  final PartyType type;
  final String workplace;
  final String branch;
  final String phone;
  final String alternatePhone;
  final String city;
  final String address;
  final String notes;
  final Money iqdBalance;
  final Money usdBalance;

  /// Compatibility projections used by the existing widgets.
  String get id => entityId.value;
  DateTime get createdAt => createdTimestamp.value.toLocal();
  num get balanceIqd => iqdBalance.majorUnits;
  num get balanceUsd => usdBalance.majorUnits;

  String get searchText => [
        number,
        name,
        type.label,
        workplace,
        branch,
        phone,
        alternatePhone,
        city,
        address,
        iqdBalance.toPlainString(),
        usdBalance.toPlainString(),
      ].join(' ').toLowerCase();

  Party copyWith({
    DateTime? createdAt,
    String? name,
    PartyType? type,
    String? workplace,
    String? branch,
    String? phone,
    String? alternatePhone,
    String? city,
    String? address,
    String? notes,
    num? balanceIqd,
    num? balanceUsd,
  }) {
    return Party.typed(
      entityId: entityId,
      number: number,
      createdTimestamp: createdAt == null
          ? createdTimestamp
          : AuditTimestamp(createdAt),
      name: name ?? this.name,
      type: type ?? this.type,
      workplace: workplace ?? this.workplace,
      branch: branch ?? this.branch,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      city: city ?? this.city,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      iqdBalance: balanceIqd == null
          ? iqdBalance
          : Money.fromMajor(balanceIqd, AppCurrency.iqd),
      usdBalance: balanceUsd == null
          ? usdBalance
          : Money.fromMajor(balanceUsd, AppCurrency.usd),
    );
  }

  Party copyWithTyped({
    AuditTimestamp? createdTimestamp,
    String? name,
    PartyType? type,
    String? workplace,
    String? branch,
    String? phone,
    String? alternatePhone,
    String? city,
    String? address,
    String? notes,
    Money? iqdBalance,
    Money? usdBalance,
  }) {
    return Party.typed(
      entityId: entityId,
      number: number,
      createdTimestamp: createdTimestamp ?? this.createdTimestamp,
      name: name ?? this.name,
      type: type ?? this.type,
      workplace: workplace ?? this.workplace,
      branch: branch ?? this.branch,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      city: city ?? this.city,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      iqdBalance: iqdBalance ?? this.iqdBalance,
      usdBalance: usdBalance ?? this.usdBalance,
    );
  }
}

void _requireCurrency(Money value, AppCurrency currency, String name) {
  if (value.currency != currency) {
    throw ArgumentError.value(value, name, 'Must use ${currency.code}');
  }
}

/// Canonical comparison form for party names.
///
/// Keeping this rule in the domain layer ensures UI validation and every
/// repository adapter reject the same Arabic spelling variants.
String normalizePartyName(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ة', 'ه');
}
