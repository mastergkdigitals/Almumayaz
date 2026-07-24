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

class PartyForm extends StatelessWidget {
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

  void _next(BuildContext context, String _) {
    AppFocusTraversal.next(context);
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
                        AppTextField(
                          fieldKey: const Key('partyNumberField'),
                          controller: controllers.number,
                          label: 'رقم الطرف',
                          icon: Icons.tag_rounded,
                          accentColor: accentColor,
                          readOnly: true,
                          enabled: false,
                        ),
                        AppTextField(
                          fieldKey: const Key('partyDateField'),
                          controller: controllers.date,
                          label: 'التاريخ',
                          icon: Icons.calendar_month_rounded,
                          accentColor: accentColor,
                          readOnly: true,
                          enabled: false,
                        ),
                        AppTextField(
                          fieldKey: const Key('partyTimeField'),
                          controller: controllers.time,
                          label: 'الوقت',
                          icon: Icons.schedule_rounded,
                          accentColor: accentColor,
                          readOnly: true,
                          enabled: false,
                        ),
                        AppTextField(
                          fieldKey: const Key('partyBalanceIqdField'),
                          controller: controllers.balanceIqd,
                          label: 'الرصيد دينار',
                          icon: Icons.payments_rounded,
                          accentColor: accentColor,
                          readOnly: true,
                          enabled: false,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                        AppTextField(
                          fieldKey: const Key('partyBalanceUsdField'),
                          controller: controllers.balanceUsd,
                          label: 'الرصيد دولار',
                          icon: Icons.attach_money_rounded,
                          accentColor: accentColor,
                          readOnly: true,
                          enabled: false,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FieldsWrap(
                      columns: compact ? 2 : 4,
                      children: [
                        AppTextField(
                          fieldKey: const Key('partyNameField'),
                          controller: controllers.name,
                          label: 'الاسم',
                          icon: Icons.person_rounded,
                          accentColor: accentColor,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (value) => _next(context, value),
                        ),
                        AppDropdownField<PartyType>(
                          key: const Key('partyTypeField'),
                          label: 'نوع الطرف',
                          icon: Icons.category_rounded,
                          accentColor: accentColor,
                          value: partyType,
                          options: [
                            for (final type in PartyType.values)
                              AppDropdownOption(
                                value: type,
                                label: type.label,
                              ),
                          ],
                          onChanged: onPartyTypeChanged,
                        ),
                        AppSearchableDropdownField<String>(
                          fieldKey: const Key('partyWorkplaceField'),
                          controller: controllers.workplace,
                          label: 'جهة العمل',
                          icon: Icons.business_rounded,
                          accentColor: accentColor,
                          options: _workplaces,
                          displayStringForOption: (value) => value,
                          onSelected: (_) {},
                          onSubmitted: (value) => _next(context, value),
                        ),
                        AppSearchableDropdownField<String>(
                          fieldKey: const Key('partyBranchField'),
                          controller: controllers.branch,
                          label: 'الفرع',
                          icon: Icons.account_tree_rounded,
                          accentColor: accentColor,
                          options: _branches,
                          displayStringForOption: (value) => value,
                          onSelected: (_) {},
                          onSubmitted: (value) => _next(context, value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FieldsWrap(
                      columns: compact ? 2 : 4,
                      children: [
                        AppTextField(
                          fieldKey: const Key('partyPhoneField'),
                          controller: controllers.phone,
                          label: 'رقم الهاتف',
                          icon: Icons.phone_rounded,
                          accentColor: accentColor,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          onSubmitted: (value) => _next(context, value),
                        ),
                        AppTextField(
                          fieldKey: const Key('partyAlternatePhoneField'),
                          controller: controllers.alternatePhone,
                          label: 'هاتف إضافي',
                          icon: Icons.phone_in_talk_rounded,
                          accentColor: accentColor,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          onSubmitted: (value) => _next(context, value),
                        ),
                        AppSearchableDropdownField<String>(
                          fieldKey: const Key('partyCityField'),
                          controller: controllers.city,
                          label: 'المدينة',
                          icon: Icons.location_city_rounded,
                          accentColor: accentColor,
                          options: _cities,
                          displayStringForOption: (value) => value,
                          onSelected: (_) {},
                          onSubmitted: (value) => _next(context, value),
                        ),
                        AppTextField(
                          fieldKey: const Key('partyAddressField'),
                          controller: controllers.address,
                          label: 'العنوان',
                          icon: Icons.location_on_rounded,
                          accentColor: accentColor,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (value) => _next(context, value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: const Key('partyNotesField'),
                      controller: controllers.notes,
                      label: 'الملاحظات',
                      icon: Icons.notes_rounded,
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
