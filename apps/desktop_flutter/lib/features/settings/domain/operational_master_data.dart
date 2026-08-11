import '../../../core/domain/business_values.dart';

enum OperationalMasterDataKind {
  itemGroup,
  itemType,
  workplace,
  branch,
  cashboxMainAccount,
  cashboxSubaccount,
}

class OperationalMasterDataRecord {
  OperationalMasterDataRecord({
    required this.id,
    required this.kind,
    required this.number,
    required String name,
    this.parentId,
    this.relatedEntityId,
    this.isProtected = false,
  }) : name = name.trim() {
    if (number < 1) throw ArgumentError.value(number, 'number');
    if (this.name.isEmpty) throw ArgumentError.value(name, 'name');
    if (_requiresParent(kind) && parentId == null) {
      throw ArgumentError.value(parentId, 'parentId', 'Parent is required');
    }
    if (!_requiresParent(kind) && parentId != null) {
      throw ArgumentError.value(parentId, 'parentId', 'Parent is not allowed');
    }
  }

  final EntityId id;
  final OperationalMasterDataKind kind;
  final int number;
  final String name;
  final EntityId? parentId;
  final EntityId? relatedEntityId;
  final bool isProtected;

  static bool _requiresParent(OperationalMasterDataKind kind) {
    return kind == OperationalMasterDataKind.itemType ||
        kind == OperationalMasterDataKind.branch ||
        kind == OperationalMasterDataKind.cashboxSubaccount;
  }
}

/// Canonical comparison form for operational master-data names.
///
/// This deliberately matches party and autocomplete comparison semantics so
/// duplicate validation cannot be bypassed with Arabic diacritics, equivalent
/// letter forms, or repeated whitespace.
String normalizeOperationalMasterDataName(String value) {
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
