import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';
import '../../../../core/domain/business_values.dart';
import '../../../settings/domain/operational_master_data.dart';
import '../../domain/party.dart';

class PartyFormControllers {
  final number = TextEditingController();
  final date = TextEditingController();
  final balanceIqd = TextEditingController();
  final balanceUsd = TextEditingController();
  final name = TextEditingController();
  final workplace = TextEditingController();
  final branch = TextEditingController();
  final phone = TextEditingController();
  final alternatePhone = TextEditingController();
  final city = TextEditingController();
  final address = TextEditingController();
  final notes = TextEditingController();

  void setNew({
    required int numberValue,
    required DateTime createdAt,
  }) {
    number.text = numberValue.toString();
    date.text = AppFormatters.date(createdAt);
    balanceIqd.text = AppFormatters.iqd(0);
    balanceUsd.text = AppFormatters.usd(0);
    name.clear();
    workplace.clear();
    branch.clear();
    phone.clear();
    alternatePhone.clear();
    city.clear();
    address.clear();
    notes.clear();
  }

  void load(Party party) {
    number.text = party.number.toString();
    date.text = AppFormatters.date(party.createdAt);
    balanceIqd.text = AppFormatters.iqd(party.balanceIqd);
    balanceUsd.text = AppFormatters.usd(party.balanceUsd);
    name.text = party.name;
    workplace.text = party.workplace;
    branch.text = party.branch;
    phone.text = party.phone;
    alternatePhone.text = party.alternatePhone;
    city.text = party.city;
    address.text = party.address;
    notes.text = party.notes;
  }

  void dispose() {
    number.dispose();
    date.dispose();
    balanceIqd.dispose();
    balanceUsd.dispose();
    name.dispose();
    workplace.dispose();
    branch.dispose();
    phone.dispose();
    alternatePhone.dispose();
    city.dispose();
    address.dispose();
    notes.dispose();
  }
}

class PartyForm extends StatefulWidget {
  const PartyForm({
    required this.controllers,
    required this.createdAt,
    required this.partyType,
    required this.workplaces,
    required this.branches,
    required this.cities,
    required this.workplaceId,
    required this.branchId,
    required this.onPartyTypeChanged,
    required this.onWorkplaceChanged,
    required this.onBranchChanged,
    this.onCreateWorkplace,
    this.onCreateBranch,
    super.key,
  });

  final PartyFormControllers controllers;
  final DateTime createdAt;
  final PartyType partyType;
  final List<OperationalMasterDataRecord> workplaces;
  final List<OperationalMasterDataRecord> branches;
  final List<String> cities;
  final EntityId? workplaceId;
  final EntityId? branchId;
  final ValueChanged<PartyType?> onPartyTypeChanged;
  final ValueChanged<EntityId?> onWorkplaceChanged;
  final ValueChanged<EntityId?> onBranchChanged;
  final Future<void> Function(String name)? onCreateWorkplace;
  final Future<void> Function(String name)? onCreateBranch;

  @override
  State<PartyForm> createState() => _PartyFormState();
}

class _PartyFormState extends State<PartyForm> {
  static final _enterKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  final _keyHoldGuard = AppKeyHoldGuard();
  final _nameFocusNode = FocusNode(debugLabel: 'partyName');
  final _typeFocusNode = FocusNode(debugLabel: 'partyType');
  final _workplaceFocusNode = FocusNode(debugLabel: 'partyWorkplace');
  final _branchFocusNode = FocusNode(debugLabel: 'partyBranch');
  final _phoneFocusNode = FocusNode(debugLabel: 'partyPhone');
  final _alternatePhoneFocusNode =
      FocusNode(debugLabel: 'partyAlternatePhone');
  final _cityFocusNode = FocusNode(debugLabel: 'partyCity');
  final _addressFocusNode = FocusNode(debugLabel: 'partyAddress');
  final _notesFocusNode = FocusNode(debugLabel: 'partyNotes');
  String? _nameErrorText;

  PartyFormControllers get controllers => widget.controllers;
  PartyType get partyType => widget.partyType;
  ValueChanged<PartyType?> get onPartyTypeChanged =>
      widget.onPartyTypeChanged;

  List<FocusNode> get _orderedFocusNodes => [
        _nameFocusNode,
        _typeFocusNode,
        _workplaceFocusNode,
        _branchFocusNode,
        _phoneFocusNode,
        _alternatePhoneFocusNode,
        _cityFocusNode,
        _addressFocusNode,
        _notesFocusNode,
      ];

  @override
  void initState() {
    super.initState();
    controllers.name.addListener(_handleNameChanged);
  }

  @override
  void didUpdateWidget(covariant PartyForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controllers.name == controllers.name) return;
    oldWidget.controllers.name.removeListener(_handleNameChanged);
    controllers.name.addListener(_handleNameChanged);
    _nameErrorText = null;
  }

  @override
  void dispose() {
    controllers.name.removeListener(_handleNameChanged);
    _keyHoldGuard.dispose();
    for (final focusNode in _orderedFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleNameChanged() {
    if (_nameErrorText == null || !mounted) return;
    setState(() => _nameErrorText = null);
  }

  void _submitName(String value) {
    if (value.trim().isEmpty) {
      setState(() => _nameErrorText = 'هذا الحقل مطلوب');
      _nameFocusNode.requestFocus();
      return;
    }

    if (_nameErrorText != null) {
      setState(() => _nameErrorText = null);
    }
    _moveFrom(_nameFocusNode);
  }

  void _moveFrom(FocusNode current, {bool guardKeyHold = true}) {
    void move() {
      final index = _orderedFocusNodes.indexOf(current);
      if (index < 0 || index >= _orderedFocusNodes.length - 1) return;
      _orderedFocusNodes[index + 1].requestFocus();
    }

    if (!guardKeyHold) {
      move();
      return;
    }

    _keyHoldGuard.runOnce(keys: _enterKeys, action: move);
  }

  List<OperationalMasterDataRecord> get _branchOptions {
    final workplaceId = widget.workplaceId;
    if (workplaceId == null) return const [];
    return widget.branches
        .where((branch) => branch.parentId == workplaceId)
        .toList(growable: false);
  }

  void _selectWorkplace(OperationalMasterDataRecord workplace) {
    widget.onWorkplaceChanged(workplace.id);
    _moveFrom(_workplaceFocusNode);
  }

  void _selectBranch(OperationalMasterDataRecord branch) {
    widget.onBranchChanged(branch.id);
    _moveFrom(_branchFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = AppColors.blue;

    return KeyedSubtree(
      key: const Key('partyForm'),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1100;
                return Column(
                  children: [
                    _FieldsWrap(
                      columns: compact ? 3 : 5,
                      children: [
                        AppReadOnlyField(
                          fieldKey: const Key('partyNumberField'),
                          controller: controllers.number,
                          label: 'رقم الطرف',
                          icon: Icons.tag_rounded,
                          accentColor: accentColor,
                        ),
                        AppReadOnlyField(
                          fieldKey: const Key('partyDateField'),
                          controller: controllers.date,
                          label: 'التاريخ',
                          icon: Icons.calendar_month_rounded,
                          accentColor: accentColor,
                        ),
                        AppTimeField(
                          fieldKey: const Key('partyTimeField'),
                          label: 'الوقت',
                          value: TimeOfDay.fromDateTime(widget.createdAt),
                          accentColor: accentColor,
                        ),
                        AppReadOnlyField(
                          fieldKey: const Key('partyBalanceIqdField'),
                          controller: controllers.balanceIqd,
                          label: 'الرصيد دينار',
                          icon: Icons.payments_rounded,
                          accentColor: accentColor,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                        AppReadOnlyField(
                          fieldKey: const Key('partyBalanceUsdField'),
                          controller: controllers.balanceUsd,
                          label: 'الرصيد دولار',
                          icon: Icons.attach_money_rounded,
                          accentColor: accentColor,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FieldsWrap(
                      columns: 2,
                      children: [
                        _TraversalField(
                          order: 1,
                          child: AppTextField(
                            fieldKey: const Key('partyNameField'),
                            controller: controllers.name,
                            label: 'الاسم',
                            errorText: _nameErrorText,
                            icon: Icons.person_rounded,
                            accentColor: accentColor,
                            focusNode: _nameFocusNode,
                            textInputAction: TextInputAction.next,
                            onSubmitted: _submitName,
                          ),
                        ),
                        _TraversalField(
                          order: 2,
                          child: AppDropdownField<PartyType>(
                            fieldKey: const Key('partyTypeField'),
                            label: 'نوع الطرف',
                            icon: Icons.category_rounded,
                            accentColor: accentColor,
                            focusNode: _typeFocusNode,
                            keyHoldGuard: _keyHoldGuard,
                            useIntrinsicHeight: true,
                            value: partyType,
                            options: [
                              for (final type in PartyType.values)
                                AppDropdownOption(
                                  value: type,
                                  label: type.label,
                                ),
                            ],
                            onChanged: onPartyTypeChanged,
                            onSubmitted: (_) => _moveFrom(
                              _typeFocusNode,
                              guardKeyHold: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FieldsWrap(
                      columns: 2,
                      children: [
                        _TraversalField(
                          order: 3,
                          child: AppAutocompleteField<
                              OperationalMasterDataRecord>(
                            fieldKey: const Key('partyWorkplaceField'),
                            controller: controllers.workplace,
                            label: 'جهة العمل',
                            icon: Icons.business_rounded,
                            accentColor: accentColor,
                            focusNode: _workplaceFocusNode,
                            options: widget.workplaces,
                            displayStringForOption: (value) => value.name,
                            searchTermsForOption: (value) => [
                              value.name,
                              '${value.number}',
                            ],
                            optionSubtitle: (value) =>
                                'رقم ${value.number}',
                            onSelected: _selectWorkplace,
                            onChanged: (_) =>
                                widget.onWorkplaceChanged(null),
                            createActionLabel: 'إضافة جهة عمل جديدة',
                            onCreateRequested: widget.onCreateWorkplace ==
                                    null
                                ? null
                                : () => widget.onCreateWorkplace!(
                                      controllers.workplace.text,
                                    ),
                            onSubmitted: (_) =>
                                _moveFrom(_workplaceFocusNode),
                          ),
                        ),
                        _TraversalField(
                          order: 4,
                          child: AppAutocompleteField<
                              OperationalMasterDataRecord>(
                            fieldKey: const Key('partyBranchField'),
                            controller: controllers.branch,
                            label: 'الفرع',
                            icon: Icons.account_tree_rounded,
                            accentColor: accentColor,
                            focusNode: _branchFocusNode,
                            options: _branchOptions,
                            displayStringForOption: (value) => value.name,
                            searchTermsForOption: (value) => [
                              value.name,
                              '${value.number}',
                            ],
                            optionSubtitle: (value) =>
                                'رقم ${value.number}',
                            onSelected: _selectBranch,
                            onChanged: (_) =>
                                widget.onBranchChanged(null),
                            createActionLabel: 'إضافة فرع جديد',
                            onCreateRequested: widget.onCreateBranch == null
                                ? null
                                : () => widget.onCreateBranch!(
                                      controllers.branch.text,
                                    ),
                            onSubmitted: (_) =>
                                _moveFrom(_branchFocusNode),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FieldsWrap(
                      columns: 2,
                      children: [
                        _TraversalField(
                          order: 5,
                          child: AppPhoneField(
                            fieldKey: const Key('partyPhoneField'),
                            controller: controllers.phone,
                            label: 'رقم الهاتف',
                            icon: Icons.phone_rounded,
                            accentColor: accentColor,
                            focusNode: _phoneFocusNode,
                            onSubmitted: (_) =>
                                _moveFrom(_phoneFocusNode),
                          ),
                        ),
                        _TraversalField(
                          order: 6,
                          child: AppPhoneField(
                            fieldKey: const Key(
                              'partyAlternatePhoneField',
                            ),
                            controller: controllers.alternatePhone,
                            label: 'هاتف إضافي',
                            icon: Icons.phone_in_talk_rounded,
                            accentColor: accentColor,
                            focusNode: _alternatePhoneFocusNode,
                            onSubmitted: (_) =>
                                _moveFrom(_alternatePhoneFocusNode),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FieldsWrap(
                      columns: 2,
                      children: [
                        _TraversalField(
                          order: 7,
                          child: AppAutocompleteField<String>(
                            fieldKey: const Key('partyCityField'),
                            controller: controllers.city,
                            label: 'المدينة',
                            icon: Icons.location_city_rounded,
                            accentColor: accentColor,
                            focusNode: _cityFocusNode,
                            options: widget.cities,
                            displayStringForOption: (value) => value,
                            onSelected: (_) => _moveFrom(_cityFocusNode),
                            onSubmitted: (_) =>
                                _moveFrom(_cityFocusNode),
                          ),
                        ),
                        _TraversalField(
                          order: 8,
                          child: AppTextField(
                            fieldKey: const Key('partyAddressField'),
                            controller: controllers.address,
                            label: 'العنوان',
                            icon: Icons.location_on_rounded,
                            accentColor: accentColor,
                            focusNode: _addressFocusNode,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                _moveFrom(_addressFocusNode),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TraversalField(
                      order: 9,
                      child: AppTextField(
                        fieldKey: const Key('partyNotesField'),
                        controller: controllers.notes,
                        label: 'الملاحظات',
                        icon: Icons.notes_rounded,
                        focusNode: _notesFocusNode,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () {},
                        onSubmitted: (_) {},
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TraversalField extends StatelessWidget {
  const _TraversalField({
    required this.order,
    required this.child,
  });

  final double order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: child,
    );
  }
}

class _FieldsWrap extends StatelessWidget {
  const _FieldsWrap({
    required this.columns,
    required this.children,
  });

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
