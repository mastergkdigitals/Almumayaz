import 'package:flutter/foundation.dart';

import '../domain/party.dart';

@immutable
class PartiesState {
  const PartiesState({
    required this.parties,
    this.query = '',
    this.selectedPartyId,
  });

  final List<Party> parties;
  final String query;
  final String? selectedPartyId;

  PartiesState copyWith({
    List<Party>? parties,
    String? query,
    Object? selectedPartyId = _unchanged,
  }) {
    return PartiesState(
      parties: parties ?? this.parties,
      query: query ?? this.query,
      selectedPartyId: identical(selectedPartyId, _unchanged)
          ? this.selectedPartyId
          : selectedPartyId as String?,
    );
  }
}

const _unchanged = Object();

class PartiesController extends ChangeNotifier {
  PartiesController({List<Party>? initialParties})
      : _state = PartiesState(
          parties: List.unmodifiable(initialParties ?? _demoParties),
        );

  PartiesState _state;

  PartiesState get state => _state;

  List<Party> get visibleParties {
    final query = _state.query.trim().toLowerCase();
    if (query.isEmpty) return _state.parties;
    return List.unmodifiable(
      _state.parties.where((party) => party.searchText.contains(query)),
    );
  }

  Party? get selectedParty {
    final selectedId = _state.selectedPartyId;
    if (selectedId == null) return null;
    for (final party in _state.parties) {
      if (party.id == selectedId) return party;
    }
    return null;
  }

  int get nextNumber {
    if (_state.parties.isEmpty) return 1;
    return _state.parties
            .map((party) => party.number)
            .reduce((first, second) => first > second ? first : second) +
        1;
  }

  void search(String value) {
    if (_state.query == value) return;
    _state = _state.copyWith(query: value);
    notifyListeners();
  }

  void select(String? partyId) {
    if (_state.selectedPartyId == partyId) return;
    _state = _state.copyWith(selectedPartyId: partyId);
    notifyListeners();
  }

  void first() => _selectAt(0);

  void previous() {
    final parties = visibleParties;
    if (parties.isEmpty) return;
    final index = _selectedVisibleIndex(parties);
    _selectAt(index <= 0 ? 0 : index - 1);
  }

  void next() {
    final parties = visibleParties;
    if (parties.isEmpty) return;
    final index = _selectedVisibleIndex(parties);
    _selectAt(
      index < 0
          ? 0
          : index >= parties.length - 1
              ? parties.length - 1
              : index + 1,
    );
  }

  void last() => _selectAt(visibleParties.length - 1);

  void add(Party party) {
    _state = _state.copyWith(
      parties: List.unmodifiable([..._state.parties, party]),
      selectedPartyId: party.id,
    );
    notifyListeners();
  }

  void update(Party party) {
    final index = _state.parties.indexWhere((item) => item.id == party.id);
    if (index < 0) return;
    final updated = [..._state.parties]..[index] = party;
    _state = _state.copyWith(parties: List.unmodifiable(updated));
    notifyListeners();
  }

  Party? deleteSelected() {
    final selected = selectedParty;
    if (selected == null) return null;
    final updated =
        _state.parties.where((party) => party.id != selected.id).toList();
    _state = _state.copyWith(
      parties: List.unmodifiable(updated),
      selectedPartyId: null,
    );
    notifyListeners();
    return selected;
  }

  void _selectAt(int index) {
    final parties = visibleParties;
    if (parties.isEmpty || index < 0 || index >= parties.length) return;
    select(parties[index].id);
  }

  int _selectedVisibleIndex(List<Party> parties) {
    return parties.indexWhere((party) => party.id == _state.selectedPartyId);
  }
}

final _demoParties = <Party>[
  Party(
    id: 'party-001',
    number: 1,
    createdAt: DateTime(2026, 7, 1, 9, 15),
    name: 'شركة النخيل للتجارة',
    type: PartyType.customerAndSupplier,
    workplace: 'التجارة العامة',
    branch: 'بغداد',
    phone: '07701234567',
    alternatePhone: '',
    city: 'بغداد',
    address: 'الكرادة',
    notes: '',
    balanceIqd: 1250000,
    balanceUsd: 850,
  ),
  Party(
    id: 'party-002',
    number: 2,
    createdAt: DateTime(2026, 7, 2, 10, 30),
    name: 'أحمد كريم',
    type: PartyType.customer,
    workplace: 'تجارة المفرد',
    branch: 'المنصور',
    phone: '07801112233',
    alternatePhone: '',
    city: 'بغداد',
    address: 'المنصور',
    notes: '',
    balanceIqd: 475000,
    balanceUsd: 0,
  ),
  Party(
    id: 'party-003',
    number: 3,
    createdAt: DateTime(2026, 7, 3, 11),
    name: 'مجهز الرافدين',
    type: PartyType.supplier,
    workplace: 'تجهيز المواد',
    branch: 'البصرة',
    phone: '07709998877',
    alternatePhone: '07809998877',
    city: 'البصرة',
    address: 'العشار',
    notes: 'التواصل صباحاً',
    balanceIqd: -3200000,
    balanceUsd: -1200,
  ),
  Party(
    id: 'party-004',
    number: 4,
    createdAt: DateTime(2026, 7, 4, 8, 45),
    name: 'سارة محمود',
    type: PartyType.employee,
    workplace: 'الإدارة',
    branch: 'الرئيسي',
    phone: '07501231234',
    alternatePhone: '',
    city: 'أربيل',
    address: 'عينكاوة',
    notes: '',
    balanceIqd: 0,
    balanceUsd: 0,
  ),
  Party(
    id: 'party-005',
    number: 5,
    createdAt: DateTime(2026, 7, 5, 12, 20),
    name: 'أسواق دجلة',
    type: PartyType.customer,
    workplace: 'تجارة الجملة',
    branch: 'النجف',
    phone: '07601110000',
    alternatePhone: '',
    city: 'النجف',
    address: 'حي الأمير',
    notes: '',
    balanceIqd: 840000,
    balanceUsd: 300,
  ),
  Party(
    id: 'party-006',
    number: 6,
    createdAt: DateTime(2026, 7, 6, 9, 5),
    name: 'شركة الموصل الحديثة',
    type: PartyType.supplier,
    workplace: 'الأجهزة المكتبية',
    branch: 'الموصل',
    phone: '07705554433',
    alternatePhone: '',
    city: 'الموصل',
    address: 'المجموعة الثقافية',
    notes: '',
    balanceIqd: -950000,
    balanceUsd: -425,
  ),
  Party(
    id: 'party-007',
    number: 7,
    createdAt: DateTime(2026, 7, 7, 14, 10),
    name: 'مكتب البصرة',
    type: PartyType.customer,
    workplace: 'الخدمات',
    branch: 'البصرة',
    phone: '07805556677',
    alternatePhone: '',
    city: 'البصرة',
    address: 'الجزائر',
    notes: '',
    balanceIqd: 210000,
    balanceUsd: 75,
  ),
  Party(
    id: 'party-008',
    number: 8,
    createdAt: DateTime(2026, 7, 8, 10, 50),
    name: 'علي حسن',
    type: PartyType.customer,
    workplace: 'تجارة المفرد',
    branch: 'الكاظمية',
    phone: '07701110022',
    alternatePhone: '',
    city: 'بغداد',
    address: 'الكاظمية',
    notes: '',
    balanceIqd: 0,
    balanceUsd: 150,
  ),
  Party(
    id: 'party-009',
    number: 9,
    createdAt: DateTime(2026, 7, 9, 13, 40),
    name: 'مجهز الفرات',
    type: PartyType.supplier,
    workplace: 'تجهيز المواد',
    branch: 'كربلاء',
    phone: '07604443322',
    alternatePhone: '',
    city: 'كربلاء',
    address: 'حي الحسين',
    notes: '',
    balanceIqd: -1725000,
    balanceUsd: 0,
  ),
  Party(
    id: 'party-010',
    number: 10,
    createdAt: DateTime(2026, 7, 10, 8, 30),
    name: 'نور فاضل',
    type: PartyType.employee,
    workplace: 'المبيعات',
    branch: 'الرئيسي',
    phone: '07507778899',
    alternatePhone: '',
    city: 'أربيل',
    address: 'الإسكان',
    notes: '',
    balanceIqd: 0,
    balanceUsd: 0,
  ),
];
