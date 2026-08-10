import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';

@immutable
class DesignGalleryManagementDialogSpec {
  const DesignGalleryManagementDialogSpec({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.primaryTitle,
    required this.secondaryTitle,
    required this.primaryFieldLabel,
    required this.secondaryFieldLabel,
    required this.primaryValues,
    required this.secondaryValues,
  });

  static const groupsAndTypes = DesignGalleryManagementDialogSpec(
    keyName: 'designGroupsTypesDialog',
    title: 'المجموعات والأنواع',
    subtitle: 'تنظيم دليل المواد',
    icon: Icons.category_rounded,
    accentColor: AppModuleColors.warehouses,
    primaryTitle: 'المجموعات',
    secondaryTitle: 'الأنواع',
    primaryFieldLabel: 'اسم المجموعة',
    secondaryFieldLabel: 'اسم النوع',
    primaryValues: ['قرطاسية', 'أجهزة مكتبية'],
    secondaryValues: ['أقلام', 'طابعات'],
  );

  static const workplaces = DesignGalleryManagementDialogSpec(
    keyName: 'designWorkplacesDialog',
    title: 'جهات العمل',
    subtitle: 'إدارة جهات العمل والفروع المرتبطة بها',
    icon: Icons.business_center_rounded,
    accentColor: AppModuleColors.parties,
    primaryTitle: 'جهات العمل',
    secondaryTitle: 'الفروع',
    primaryFieldLabel: 'اسم جهة العمل',
    secondaryFieldLabel: 'اسم الفرع',
    primaryValues: ['شركة النور', 'أسواق دجلة'],
    secondaryValues: ['الفرع الرئيسي', 'فرع الكرادة'],
  );

  static const cashboxTabs = DesignGalleryManagementDialogSpec(
    keyName: 'designCashboxTabsDialog',
    title: 'تبويبات الصندوق',
    subtitle: 'إدارة الحسابات الرئيسية والفرعية',
    icon: Icons.account_balance_wallet_rounded,
    accentColor: AppModuleColors.cashbox,
    primaryTitle: 'الحسابات الرئيسية',
    secondaryTitle: 'الحسابات الفرعية',
    primaryFieldLabel: 'اسم الحساب الرئيسي',
    secondaryFieldLabel: 'اسم الحساب الفرعي',
    primaryValues: ['الأطراف', 'المصاريف'],
    secondaryValues: ['نقل', 'صيانة'],
  );

  final String keyName;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String primaryTitle;
  final String secondaryTitle;
  final String primaryFieldLabel;
  final String secondaryFieldLabel;
  final List<String> primaryValues;
  final List<String> secondaryValues;
}

abstract final class DesignGalleryManagementDialog {
  static Future<void> show(
    BuildContext context,
    DesignGalleryManagementDialogSpec spec,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ManagementDialog(spec: spec),
      ),
    );
  }
}

class _ManagementDialog extends StatefulWidget {
  const _ManagementDialog({required this.spec});

  final DesignGalleryManagementDialogSpec spec;

  @override
  State<_ManagementDialog> createState() => _ManagementDialogState();
}

class _ManagementDialogState extends State<_ManagementDialog> {
  late List<AppManagementEntry> _primaryEntries;
  late List<AppManagementEntry> _secondaryEntries;
  late String _selectedParentId;
  var _seed = 100;

  DesignGalleryManagementDialogSpec get _spec => widget.spec;

  @override
  void initState() {
    super.initState();
    _primaryEntries = [
      for (var index = 0; index < _spec.primaryValues.length; index++)
        AppManagementEntry(
          id: 'primary-$index',
          number: index + 1,
          name: _spec.primaryValues[index],
          isProtected: index == 0,
        ),
    ];
    _selectedParentId = _primaryEntries.first.id;
    final numbersByParent = <String, int>{};
    _secondaryEntries = [
      for (var index = 0; index < _spec.secondaryValues.length; index++)
        _secondarySeedEntry(index, numbersByParent),
    ];
  }

  AppManagementEntry _secondarySeedEntry(
    int index,
    Map<String, int> numbersByParent,
  ) {
    final parentIndex = index.clamp(0, _primaryEntries.length - 1).toInt();
    final parentId = _primaryEntries[parentIndex].id;
    final number = (numbersByParent[parentId] ?? 0) + 1;
    numbersByParent[parentId] = number;
    return AppManagementEntry(
      id: 'secondary-$index',
      number: number,
      name: _spec.secondaryValues[index],
      parentId: parentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: Key(_spec.keyName),
      title: _spec.title,
      subtitle: _spec.subtitle,
      icon: _spec.icon,
      accentColor: _spec.accentColor,
      width: AppDialogSizes.extraLarge,
      onClose: () => Navigator.of(context).pop(),
      actionsKey: Key('${_spec.keyName}Actions'),
      actions: [
        AppButton(
          key: Key('${_spec.keyName}Cancel'),
          label: 'إغلاق',
          variant: AppButtonVariant.secondary,
          width: 144,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          key: Key('${_spec.keyName}Confirm'),
          label: 'حفظ',
          icon: Icons.save_rounded,
          width: 144,
          backgroundColor: _spec.accentColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: SizedBox(
        key: Key('${_spec.keyName}Content'),
        height: 520,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildPrimarySection()),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildSecondarySection()),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimarySection() {
    return AppDialogSection(
      title: _spec.primaryTitle,
      icon: Icons.folder_rounded,
      accentColor: _spec.accentColor,
      expandChild: true,
      child: AppManagementPanel(
        key: Key('${_spec.keyName}PrimaryPanel'),
        keys: AppManagementPanelKeys(
          prefix: _spec.keyName,
          nameFieldSuffix: 'PrimaryField',
          addButtonSuffix: 'PrimaryCommit',
          updateButtonSuffix: 'PrimaryUpdate',
          clearButtonSuffix: 'PrimaryClear',
          tableSuffix: 'PrimaryList',
          rowSeparator: 'PrimaryRow-',
          deleteSeparator: 'PrimaryDelete-',
        ),
        fieldLabel: _spec.primaryFieldLabel,
        accentColor: _spec.accentColor,
        entries: _primaryEntries,
        referencedEntryIds: {
          for (final entry in _secondaryEntries) entry.parentId!,
        },
        selectedEntryId: _selectedParentId,
        tableHeight: 220,
        minimumColumnWidth: 90,
        onSelectionChanged: (entry) {
          if (entry == null || entry.id == _selectedParentId) return;
          setState(() => _selectedParentId = entry.id);
        },
        onCreate: _createPrimary,
        onUpdate: _updatePrimary,
        onDelete: _deletePrimary,
      ),
    );
  }

  Widget _buildSecondarySection() {
    return AppDialogSection(
      title: _spec.secondaryTitle,
      icon: Icons.account_tree_rounded,
      accentColor: _spec.accentColor,
      expandChild: true,
      child: AppManagementPanel(
        key: Key('${_spec.keyName}SecondaryPanel'),
        keys: AppManagementPanelKeys(
          prefix: _spec.keyName,
          parentFieldSuffix: 'ParentDropdown',
          nameFieldSuffix: 'SecondaryField',
          addButtonSuffix: 'SecondaryCommit',
          updateButtonSuffix: 'SecondaryUpdate',
          clearButtonSuffix: 'SecondaryClear',
          tableSuffix: 'SecondaryList',
          rowSeparator: 'SecondaryRow-',
          deleteSeparator: 'SecondaryDelete-',
        ),
        fieldLabel: _spec.secondaryFieldLabel,
        parentLabel: _spec.primaryTitle,
        accentColor: _spec.accentColor,
        entries: _secondaryEntries,
        parentOptions: _primaryEntries,
        selectedParentId: _selectedParentId,
        tableHeight: 220,
        minimumColumnWidth: 80,
        onParentChanged: (parentId) {
          if (parentId == _selectedParentId) return;
          setState(() => _selectedParentId = parentId);
        },
        onCreate: _createSecondary,
        onUpdate: _updateSecondary,
        onDelete: _deleteSecondary,
      ),
    );
  }

  Future<AppManagementEntry> _createPrimary(
    AppManagementEntryDraft draft,
  ) async {
    final entry = AppManagementEntry(
      id: 'primary-${_seed++}',
      number: draft.number,
      name: draft.name,
    );
    setState(() => _primaryEntries = [..._primaryEntries, entry]);
    return entry;
  }

  Future<AppManagementEntry> _updatePrimary(
    AppManagementEntry existing,
    AppManagementEntryDraft draft,
  ) async {
    final entry = existing.copyWith(name: draft.name);
    setState(() {
      _primaryEntries = _replaceEntry(_primaryEntries, entry);
    });
    return entry;
  }

  Future<void> _deletePrimary(AppManagementEntry entry) async {
    setState(() {
      _primaryEntries = [
        for (final item in _primaryEntries)
          if (item.id != entry.id) item,
      ];
      if (_selectedParentId == entry.id) {
        _selectedParentId = _primaryEntries.first.id;
      }
    });
  }

  Future<AppManagementEntry> _createSecondary(
    AppManagementEntryDraft draft,
  ) async {
    final entry = AppManagementEntry(
      id: 'secondary-${_seed++}',
      number: draft.number,
      name: draft.name,
      parentId: draft.parentId,
    );
    setState(() => _secondaryEntries = [..._secondaryEntries, entry]);
    return entry;
  }

  Future<AppManagementEntry> _updateSecondary(
    AppManagementEntry existing,
    AppManagementEntryDraft draft,
  ) async {
    final entry = existing.copyWith(
      name: draft.name,
      parentId: draft.parentId,
    );
    setState(() {
      _secondaryEntries = _replaceEntry(_secondaryEntries, entry);
    });
    return entry;
  }

  Future<void> _deleteSecondary(AppManagementEntry entry) async {
    setState(() {
      _secondaryEntries = [
        for (final item in _secondaryEntries)
          if (item.id != entry.id) item,
      ];
    });
  }
}

List<AppManagementEntry> _replaceEntry(
  List<AppManagementEntry> entries,
  AppManagementEntry replacement,
) {
  return [
    for (final entry in entries)
      if (entry.id == replacement.id) replacement else entry,
  ];
}
