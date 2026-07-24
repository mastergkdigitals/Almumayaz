import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/party.dart';

class PartyFormControllers {
  final number = TextEditingController();
  final date = TextEditingController();
  final time = TextEditingController();
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
    time.text = AppFormatters.time(TimeOfDay.fromDateTime(createdAt));
    balanceIqd.text = '0';
    balanceUsd.text = '0';
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
    time.text = AppFormatters.time(TimeOfDay.fromDateTime(party.createdAt));
    balanceIqd.text = AppFormatters.money(party.balanceIqd);
    balanceUsd.text = AppFormatters.money(party.balanceUsd);
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
    time.dispose();
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
    required this.partyType,
    required this.onPartyTypeChanged,
    super.key,
  });

  static const _workplaces = [
    'التجارة العامة',
    'تجارة الجملة',
    'تجارة المفرد',
    'تجهيز المواد',
    'الأجهزة المكتبية',
    'الخدمات',
    'الإدارة',
    'المبيعات',
  ];

  static const _branches = [
    'الرئيسي',
    'بغداد',
    'المنصور',
    'الكاظمية',
    'البصرة',
    'أربيل',
    'النجف',
    'الموصل',
    'كربلاء',
  ];

  static const _cities = [
    'بغداد',
    'البصرة',
    'أربيل',
    'النجف',
    'الموصل',
    'كربلاء',
  ];

  final PartyFormControllers controllers;
  final PartyType partyType;
  final ValueChanged<PartyType?> onPartyTypeChanged;

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

  PartyFormControllers get controllers => widget.controllers;
  PartyType get partyType => widget.partyType;
  ValueChanged<PartyType?> get onPartyTypeChanged =>
      widget.onPartyTypeChanged;
  List<String> get _workplaces => PartyForm._workplaces;
  List<String> get _branches => PartyForm._branches;
  List<String> get _cities => PartyForm._cities;

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
  void dispose() {
    _keyHoldGuard.dispose();
    for (final focusNode in _orderedFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
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

  void _moveWithTab({required bool backwards}) {
    _keyHoldGuard.runOnce(
      keys: {LogicalKeyboardKey.tab},
      action: () {
        final nodes = _orderedFocusNodes;
        final currentIndex =
            nodes.indexWhere((focusNode) => focusNode.hasFocus);
        if (currentIndex < 0) {
          (backwards ? nodes.last : nodes.first).requestFocus();
          return;
        }

        final targetIndex = backwards
            ? (currentIndex - 1).clamp(0, nodes.length - 1)
            : (currentIndex + 1).clamp(0, nodes.length - 1);
        nodes[targetIndex.toInt()].requestFocus();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = AppModuleColors.parties;

    return Container(
      key: const Key('partyForm'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.tab):
              () => _moveWithTab(backwards: false),
          const SingleActivator(LogicalKeyboardKey.tab, shift: true):
              () => _moveWithTab(backwards: true),
        },
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
                        AppReadOnlyField(
                          fieldKey: const Key('partyTimeField'),
                          controller: controllers.time,
                          label: 'الوقت',
                          icon: Icons.schedule_rounded,
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
                      columns: compact ? 2 : 4,
                      children: [
                        _TraversalField(
                          order: 1,
                          child: AppTextField(
                            fieldKey: const Key('partyNameField'),
                            controller: controllers.name,
                            label: 'الاسم',
                            icon: Icons.person_rounded,
                            accentColor: accentColor,
                            focusNode: _nameFocusNode,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _moveFrom(_nameFocusNode),
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
                        _TraversalField(
                          order: 3,
                          child: AppSearchableDropdownField<String>(
                            fieldKey: const Key('partyWorkplaceField'),
                            controller: controllers.workplace,
                            label: 'جهة العمل',
                            icon: Icons.business_rounded,
                            accentColor: accentColor,
                            focusNode: _workplaceFocusNode,
                            options: _workplaces,
                            displayStringForOption: (value) => value,
                            onSelected: (_) {},
                            onSubmitted: (_) =>
                                _moveFrom(_workplaceFocusNode),
                          ),
                        ),
                        _TraversalField(
                          order: 4,
                          child: AppSearchableDropdownField<String>(
                            fieldKey: const Key('partyBranchField'),
                            controller: controllers.branch,
                            label: 'الفرع',
                            icon: Icons.account_tree_rounded,
                            accentColor: accentColor,
                            focusNode: _branchFocusNode,
                            options: _branches,
                            displayStringForOption: (value) => value,
                            onSelected: (_) {},
                            onSubmitted: (_) => _moveFrom(_branchFocusNode),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FieldsWrap(
                      columns: compact ? 2 : 4,
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
                            onSubmitted: (_) => _moveFrom(_phoneFocusNode),
                          ),
                        ),
                        _TraversalField(
                          order: 6,
                          child: AppPhoneField(
                            fieldKey:
                                const Key('partyAlternatePhoneField'),
                            controller: controllers.alternatePhone,
                            label: 'هاتف إضافي',
                            icon: Icons.phone_in_talk_rounded,
                            accentColor: accentColor,
                            focusNode: _alternatePhoneFocusNode,
                            onSubmitted: (_) =>
                                _moveFrom(_alternatePhoneFocusNode),
                          ),
                        ),
                        _TraversalField(
                          order: 7,
                          child: AppSearchableDropdownField<String>(
                            fieldKey: const Key('partyCityField'),
                            controller: controllers.city,
                            label: 'المدينة',
                            icon: Icons.location_city_rounded,
                            accentColor: accentColor,
                            focusNode: _cityFocusNode,
                            options: _cities,
                            displayStringForOption: (value) => value,
                            onSelected: (_) {},
                            onSubmitted: (_) => _moveFrom(_cityFocusNode),
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
                            onSubmitted: (_) => _moveFrom(_addressFocusNode),
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
