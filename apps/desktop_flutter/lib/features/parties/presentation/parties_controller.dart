import 'package:flutter/foundation.dart';

import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../settings/domain/operational_master_data.dart';
import '../../settings/domain/operational_master_data_repository.dart';
import '../domain/party.dart';
import '../domain/party_repository.dart';

@immutable
class PartiesState {
  const PartiesState({
    this.dataState = const AppDataState.loading(),
    this.query = '',
    this.selectedPartyEntityId,
    this.workplaces = const [],
    this.branches = const [],
  });

  final AppDataState<List<Party>> dataState;
  final String query;
  final EntityId? selectedPartyEntityId;
  String? get selectedPartyId => selectedPartyEntityId?.value;
  final List<OperationalMasterDataRecord> workplaces;
  final List<OperationalMasterDataRecord> branches;

  List<Party> get parties => dataState.data ?? const [];

  PartiesState copyWith({
    AppDataState<List<Party>>? dataState,
    String? query,
    Object? selectedPartyEntityId = _unchanged,
    List<OperationalMasterDataRecord>? workplaces,
    List<OperationalMasterDataRecord>? branches,
  }) {
    return PartiesState(
      dataState: dataState ?? this.dataState,
      query: query ?? this.query,
      selectedPartyEntityId:
          identical(selectedPartyEntityId, _unchanged)
              ? this.selectedPartyEntityId
              : selectedPartyEntityId as EntityId?,
      workplaces: workplaces ?? this.workplaces,
      branches: branches ?? this.branches,
    );
  }
}

const _unchanged = Object();

class PartiesController extends ChangeNotifier {
  PartiesController({
    required PartyRepository repository,
    required OperationalMasterDataRepository masterData,
    VoidCallback? onDataChanged,
  })  : _repository = repository,
        _masterData = masterData,
        _onDataChanged = onDataChanged;

  final PartyRepository _repository;
  final OperationalMasterDataRepository _masterData;
  final VoidCallback? _onDataChanged;

  PartiesState _state = const PartiesState();
  bool _isDisposed = false;
  int _loadGeneration = 0;

  PartiesState get state => _state;

  List<Party> get visibleParties {
    final query = _state.query.trim().toLowerCase();
    if (query.isEmpty) return _state.parties;
    return List.unmodifiable(
      _state.parties.where((party) => party.searchText.contains(query)),
    );
  }

  List<String> get workplaceSuggestions => List.unmodifiable(
        _state.workplaces.map((record) => record.name),
      );

  List<String> get branchSuggestions => List.unmodifiable(
        _state.branches.map((record) => record.name).toSet(),
      );

  List<String> get citySuggestions => List.unmodifiable(
        _state.parties
            .map((party) => party.city.trim())
            .where((city) => city.isNotEmpty)
            .toSet(),
      );

  Party? get selectedParty {
    final selectedId = _state.selectedPartyEntityId;
    if (selectedId == null) return null;
    for (final party in _state.parties) {
      if (party.entityId == selectedId) return party;
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

  Future<void> load() async {
    if (_isDisposed) return;
    final generation = ++_loadGeneration;
    _state = _state.copyWith(dataState: const AppDataState.loading());
    _notifyListenersIfActive();
    try {
      final parties = await _repository.getAll();
      final workplaces = await _masterData.getByKind(
        OperationalMasterDataKind.workplace,
      );
      final branches = await _masterData.getByKind(
        OperationalMasterDataKind.branch,
      );
      if (_loadIsStale(generation)) return;
      final resolved = <Party>[];
      for (final party in parties) {
        final references = await _repository.getMasterDataReferences(
          party.entityId,
        );
        if (_loadIsStale(generation)) return;
        if (references == null) {
          _setMissingReference(
            'بيانات جهة العمل للطرف ${party.name} غير متاحة',
            generation,
          );
          return;
        }
        if (references.workplaceId == null && references.branchId == null) {
          resolved.add(party.copyWith(workplace: '', branch: ''));
          continue;
        }
        final workplace = _recordById(workplaces, references.workplaceId);
        final branch = _recordById(branches, references.branchId);
        if (workplace == null || branch == null) {
          _setMissingReference(
            'جهة العمل أو الفرع للطرف ${party.name} غير متاح',
            generation,
          );
          return;
        }
        if (branch.parentId != workplace.id) {
          _setMissingReference(
            'الفرع المرتبط بالطرف ${party.name} غير صالح',
            generation,
          );
          return;
        }
        resolved.add(
          party.copyWith(workplace: workplace.name, branch: branch.name),
        );
      }
      _state = _state.copyWith(
        dataState: resolved.isEmpty
            ? const AppDataState.empty(message: 'لا توجد أطراف مسجلة حالياً.')
            : AppDataState.ready(List.unmodifiable(resolved)),
        workplaces: List.unmodifiable(workplaces),
        branches: List.unmodifiable(branches),
        selectedPartyEntityId: resolved.any(
          (party) => party.entityId == _state.selectedPartyEntityId,
        )
            ? _state.selectedPartyEntityId
            : null,
      );
      _notifyListenersIfActive();
    } catch (error) {
      if (_loadIsStale(generation)) return;
      _state = _state.copyWith(
        dataState: AppDataState.error(
          error,
          message: 'تعذر تحميل بيانات الأطراف.',
        ),
      );
      _notifyListenersIfActive();
    }
  }

  void search(String value) {
    if (_isDisposed) return;
    if (_state.query == value) return;
    _state = _state.copyWith(query: value);
    _notifyListenersIfActive();
  }

  void select(String? partyId) {
    if (_isDisposed) return;
    final entityId = partyId == null ? null : EntityId(partyId);
    if (_state.selectedPartyEntityId == entityId) return;
    _state = _state.copyWith(selectedPartyEntityId: entityId);
    _notifyListenersIfActive();
  }

  int get selectedVisibleIndex => _selectedVisibleIndex(visibleParties);

  void first() => _selectAt(0);

  void previous() {
    final parties = visibleParties;
    if (parties.isEmpty) return;
    final index = _selectedVisibleIndex(parties);
    if (index < 0) {
      _selectAt(parties.length - 1);
      return;
    }
    _selectAt(index <= 0 ? 0 : index - 1);
  }

  void next() {
    final parties = visibleParties;
    if (parties.isEmpty) {
      select(null);
      return;
    }
    final index = _selectedVisibleIndex(parties);
    if (index < 0) {
      _selectAt(0);
      return;
    }
    if (index >= parties.length - 1) {
      select(null);
      return;
    }
    _selectAt(index + 1);
  }

  void last() {
    final parties = visibleParties;
    if (parties.isEmpty) {
      select(null);
      return;
    }
    final index = _selectedVisibleIndex(parties);
    if (index == parties.length - 1) {
      select(null);
      return;
    }
    _selectAt(parties.length - 1);
  }

  bool nameExists(String name, {String? exceptPartyId}) {
    final normalized = normalizePartyName(name);
    return _state.parties.any(
      (party) =>
          party.entityId.value != exceptPartyId &&
          normalizePartyName(party.name) == normalized,
    );
  }

  Future<Party> add(Party party) async {
    final saved = await _saveWithResolvedReferences(party);
    if (_isDisposed) return saved;
    await load();
    if (_isDisposed) return saved;
    select(saved.entityId.value);
    _onDataChanged?.call();
    return selectedParty ?? saved;
  }

  Future<Party> update(Party party) async {
    final saved = await _saveWithResolvedReferences(party);
    if (_isDisposed) return saved;
    await load();
    if (_isDisposed) return saved;
    select(saved.entityId.value);
    _onDataChanged?.call();
    return selectedParty ?? saved;
  }

  Future<DeleteDecision> canDeleteSelected() async {
    final selected = selectedParty;
    if (selected == null) {
      return const DeleteDecision.blocked('اختر طرفاً من الجدول لحذفه');
    }
    return _repository.canDelete(selected.entityId);
  }

  Future<Party?> deleteSelected() async {
    final selected = selectedParty;
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

  Future<Party> _saveWithResolvedReferences(Party party) async {
    final workplaceName = party.workplace.trim();
    final branchName = party.branch.trim();
    if (workplaceName.isEmpty && branchName.isEmpty) {
      return _repository.saveWithMasterData(
        party,
        const PartyMasterDataReferences(),
      );
    }
    if (workplaceName.isEmpty || branchName.isEmpty) {
      throw StateError('اختر جهة العمل والفرع معاً');
    }
    final workplace = _state.workplaces.where(
      (record) => record.name.trim() == workplaceName,
    );
    if (workplace.length != 1) {
      throw StateError('اختر جهة عمل موجودة من القائمة');
    }
    final branches = _state.branches.where(
      (record) =>
          record.parentId == workplace.single.id &&
          record.name.trim() == branchName,
    );
    if (branches.length != 1) {
      throw StateError('اختر فرعاً تابعاً لجهة العمل من القائمة');
    }
    return _repository.saveWithMasterData(
      party,
      PartyMasterDataReferences(
        workplaceId: workplace.single.id,
        branchId: branches.single.id,
      ),
    );
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

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration++;
    super.dispose();
  }

  OperationalMasterDataRecord? _recordById(
    List<OperationalMasterDataRecord> records,
    EntityId? id,
  ) {
    if (id == null) return null;
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  void _selectAt(int index) {
    final parties = visibleParties;
    if (parties.isEmpty || index < 0 || index >= parties.length) return;
    select(parties[index].entityId.value);
  }

  int _selectedVisibleIndex(List<Party> parties) {
    return parties.indexWhere(
      (party) => party.entityId == _state.selectedPartyEntityId,
    );
  }
}
