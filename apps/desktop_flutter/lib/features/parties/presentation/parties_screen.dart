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

  @override
  void initState() {
    super.initState();
    _setNewForm();
  }

  @override
  void dispose() {
    _partiesController.dispose();
    _formControllers.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setNewForm() {
    _createdAt = DateTime.now();
    _partyType = PartyType.customer;
    _formControllers.setNew(
      numberValue: _partiesController.nextNumber,
      createdAt: _createdAt,
    );
  }

  void _newParty() {
    _partiesController.select(null);
    setState(_setNewForm);
  }

  void _loadParty(Party party) {
    _formControllers.load(party);
    setState(() {
      _createdAt = party.createdAt;
      _partyType = party.type;
    });
  }

  void _selectParty(Party party) {
    _partiesController.select(party.id);
    _loadParty(party);
  }

  void _navigate(VoidCallback navigation) {
    navigation();
    final selected = _partiesController.selectedParty;
    if (selected != null) _loadParty(selected);
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

  void _refresh() {
    setState(() {});
    AppToast.showInfo(context, 'تم تحديث الشاشة');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _partiesController,
      builder: (context, _) {
        return AppScreenShell(
          key: const Key('partiesScreen'),
          title: 'الأطراف',
          subtitle: 'إدارة بيانات الزبائن والمجهزين والموظفين',
          onBack: () => Navigator.of(context).pop(),
          onSearch: _searchFocusNode.requestFocus,
          onSave: _save,
          onNew: _newParty,
          onRefresh: _refresh,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                PartyForm(
                  controllers: _formControllers,
                  partyType: _partyType,
                  onPartyTypeChanged: (value) {
                    if (value == null) return;
                    setState(() => _partyType = value);
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
                  onFirst: () => _navigate(_partiesController.first),
                  onPrevious: () => _navigate(_partiesController.previous),
                  onNext: () => _navigate(_partiesController.next),
                  onLast: () => _navigate(_partiesController.last),
                  onSave: _save,
                  onUpdate: _update,
                  onUndo: _undo,
                  onDelete: _delete,
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
