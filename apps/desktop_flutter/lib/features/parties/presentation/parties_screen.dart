import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import '../domain/party.dart';
import 'parties_controller.dart';
import 'widgets/parties_table.dart';
import 'widgets/party_form.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  final _partiesController = PartiesController();
  final _formControllers = PartyFormControllers();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  PartyType _partyType = PartyType.customer;
  DateTime _createdAt = DateTime.now();
  late _PartyFormSnapshot _baseline;
  bool _isApplyingFormState = false;
  bool _hasUnsavedChanges = false;

  Iterable<TextEditingController> get _editableControllers => [
        _formControllers.name,
        _formControllers.workplace,
        _formControllers.branch,
        _formControllers.phone,
        _formControllers.alternatePhone,
        _formControllers.city,
        _formControllers.address,
        _formControllers.notes,
      ];

  @override
  void initState() {
    super.initState();
    _setNewForm();
    for (final controller in _editableControllers) {
      controller.addListener(_refreshUnsavedState);
    }
  }

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_refreshUnsavedState);
    }
    _partiesController.dispose();
    _formControllers.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setNewForm() {
    _isApplyingFormState = true;
    _createdAt = DateTime.now();
    _partyType = PartyType.customer;
    _formControllers.setNew(
      numberValue: _partiesController.nextNumber,
      createdAt: _createdAt,
    );
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  void _newParty() {
    _partiesController.select(null);
    setState(_setNewForm);
  }

  void _loadParty(Party party) {
    _isApplyingFormState = true;
    _formControllers.load(party);
    _createdAt = party.createdAt;
    _partyType = party.type;
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    setState(() => _hasUnsavedChanges = false);
  }

  void _selectParty(Party party) {
    if (_partiesController.selectedParty?.id == party.id) return;
    unawaited(_selectPartyAfterConfirmation(party));
  }

  Future<void> _selectPartyAfterConfirmation(Party party) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    _partiesController.select(party.id);
    _loadParty(party);
  }

  void _navigate(VoidCallback navigation) {
    unawaited(_navigateAfterConfirmation(navigation));
  }

  Future<void> _navigateAfterConfirmation(VoidCallback navigation) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    navigation();
    final selected = _partiesController.selectedParty;
    if (selected == null) {
      setState(_setNewForm);
    } else {
      _loadParty(selected);
    }
  }

  _PartyFormSnapshot _currentSnapshot() => (
        name: _formControllers.name.text,
        type: _partyType,
        workplace: _formControllers.workplace.text,
        branch: _formControllers.branch.text,
        phone: _formControllers.phone.text,
        alternatePhone: _formControllers.alternatePhone.text,
        city: _formControllers.city.text,
        address: _formControllers.address.text,
        notes: _formControllers.notes.text,
      );

  void _refreshUnsavedState() {
    if (_isApplyingFormState || !mounted) return;
    final hasUnsavedChanges = _currentSnapshot() != _baseline;
    if (_hasUnsavedChanges == hasUnsavedChanges) return;
    setState(() => _hasUnsavedChanges = hasUnsavedChanges);
  }

  void _changePartyType(PartyType value) {
    if (_partyType == value) return;
    setState(() {
      _partyType = value;
      _hasUnsavedChanges = _currentSnapshot() != _baseline;
    });
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    return AppDialogs.confirm(
      context: context,
      title: 'تغييرات غير محفوظة',
      message: 'لديك بيانات أو تعديلات غير محفوظة. هل تريد تجاهلها؟',
      confirmLabel: 'تجاهل',
      cancelLabel: 'البقاء',
      isDanger: true,
    );
  }

  void _attemptBack() {
    unawaited(_leaveAfterConfirmation());
  }

  Future<void> _leaveAfterConfirmation() async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    Navigator.of(context).pop();
  }

  bool _validateName() {
    if (_formControllers.name.text.trim().isNotEmpty) return true;
    AppToast.showWarning(context, 'أدخل اسم الطرف أولاً');
    return false;
  }

  Party _newPartyFromForm() {
    return Party(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      number: _partiesController.nextNumber,
      createdAt: _createdAt,
      name: _formControllers.name.text.trim(),
      type: _partyType,
      workplace: _formControllers.workplace.text.trim(),
      branch: _formControllers.branch.text.trim(),
      phone: _formControllers.phone.text.trim(),
      alternatePhone: _formControllers.alternatePhone.text.trim(),
      city: _formControllers.city.text.trim(),
      address: _formControllers.address.text.trim(),
      notes: _formControllers.notes.text.trim(),
      balanceIqd: 0,
      balanceUsd: 0,
    );
  }

  Party _updatedPartyFromForm(Party current) {
    return current.copyWith(
      createdAt: _createdAt,
      name: _formControllers.name.text.trim(),
      type: _partyType,
      workplace: _formControllers.workplace.text.trim(),
      branch: _formControllers.branch.text.trim(),
      phone: _formControllers.phone.text.trim(),
      alternatePhone: _formControllers.alternatePhone.text.trim(),
      city: _formControllers.city.text.trim(),
      address: _formControllers.address.text.trim(),
      notes: _formControllers.notes.text.trim(),
    );
  }

  void _save() {
    if (!_validateName()) return;
    if (_partiesController.selectedParty != null) {
      AppToast.showWarning(context, 'استخدم زر تحديث لتعديل الطرف المحدد');
      return;
    }

    final party = _newPartyFromForm();
    _partiesController.add(party);
    _loadParty(party);
    AppToast.showSuccess(context, 'تم حفظ الطرف مؤقتاً');
  }

  void _update() {
    final selected = _partiesController.selectedParty;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر طرفاً من الجدول لتحديثه');
      return;
    }
    if (!_validateName()) return;

    final updated = _updatedPartyFromForm(selected);
    _partiesController.update(updated);
    _loadParty(updated);
    AppToast.showSuccess(context, 'تم تحديث الطرف مؤقتاً');
  }

  void _undo() {
    final selected = _partiesController.selectedParty;
    if (selected == null) {
      _newParty();
    } else {
      _loadParty(selected);
    }
    AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  Future<void> _delete() async {
    final selected = _partiesController.selectedParty;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر طرفاً من الجدول لحذفه');
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف الطرف',
      message: 'هل تريد حذف ${selected.name}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;

    _partiesController.deleteSelected();
    setState(_setNewForm);
    AppToast.showDanger(context, 'تم حذف الطرف مؤقتاً');
  }

  void _showStatement(Party party) {
    AppToast.showInfo(
      context,
      'سيتم ربط كشف حساب ${party.name} مع الخدمات لاحقاً',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _partiesController,
      builder: (context, _) {
        final hasSelectedParty = _partiesController.selectedParty != null;
        final visibleParties = _partiesController.visibleParties;
        final selectedVisibleIndex =
            _partiesController.selectedVisibleIndex;
        final hasVisibleParties = visibleParties.isNotEmpty;
        final canMoveToFirstOrPrevious =
            hasVisibleParties && selectedVisibleIndex != 0;
        final canMoveToNextOrLast =
            hasVisibleParties && selectedVisibleIndex >= 0;

        return AppScreenShell(
          key: const Key('partiesScreen'),
          title: 'الأطراف',
          subtitle: 'إدارة بيانات الزبائن والمجهزين والموظفين',
          onBack: _attemptBack,
          onSearch: _searchFocusNode.requestFocus,
          onSave: hasSelectedParty
              ? _hasUnsavedChanges
                  ? _update
                  : null
              : _save,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                PartyForm(
                  controllers: _formControllers,
                  partyType: _partyType,
                  onPartyTypeChanged: (value) {
                    if (value == null) return;
                    _changePartyType(value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppActionBar(
                  key: const Key('partiesActionBar'),
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  searchFieldKey: const Key('partiesSearchField'),
                  searchClearButtonKey:
                      const Key('partiesSearchClearButton'),
                  firstButtonKey: const Key('partiesFirstButton'),
                  previousButtonKey: const Key('partiesPreviousButton'),
                  nextButtonKey: const Key('partiesNextButton'),
                  lastButtonKey: const Key('partiesLastButton'),
                  saveButtonKey: const Key('partiesSaveButton'),
                  updateButtonKey: const Key('partiesUpdateButton'),
                  undoButtonKey: const Key('partiesUndoButton'),
                  deleteButtonKey: const Key('partiesDeleteButton'),
                  searchHint: 'الاسم أو النوع أو الهاتف أو المدينة',
                  onSearchChanged: _partiesController.search,
                  onFirst: canMoveToFirstOrPrevious
                      ? () => _navigate(_partiesController.first)
                      : null,
                  onPrevious: canMoveToFirstOrPrevious
                      ? () => _navigate(_partiesController.previous)
                      : null,
                  onNext: canMoveToNextOrLast
                      ? () => _navigate(_partiesController.next)
                      : null,
                  onLast: canMoveToNextOrLast
                      ? () => _navigate(_partiesController.last)
                      : null,
                  onSave: hasSelectedParty ? null : _save,
                  onUpdate:
                      hasSelectedParty && _hasUnsavedChanges ? _update : null,
                  onUndo: _hasUnsavedChanges ? _undo : null,
                  onDelete: hasSelectedParty ? _delete : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return PartiesTable(
                        parties: _partiesController.visibleParties,
                        selectedPartyId:
                            _partiesController.state.selectedPartyId,
                        onSelected: _selectParty,
                        onStatement: _showStatement,
                        height: constraints.maxHeight,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

typedef _PartyFormSnapshot = ({
  String name,
  PartyType type,
  String workplace,
  String branch,
  String phone,
  String alternatePhone,
  String city,
  String address,
  String notes,
});
