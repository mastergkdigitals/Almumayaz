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
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();

  late final List<_ManagementEntry> _primaryEntries;
  late final List<_ManagementEntry> _secondaryEntries;
  late String _selectedParentId;

  String? _editingPrimaryId;
  String? _editingSecondaryId;
  var _seed = 100;

  DesignGalleryManagementDialogSpec get _spec => widget.spec;

  List<_ManagementEntry> get _visibleSecondaryEntries {
    return _secondaryEntries
        .where((entry) => entry.parentId == _selectedParentId)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _primaryEntries = [
      for (var index = 0; index < _spec.primaryValues.length; index++)
        _ManagementEntry(
          id: 'primary-' + index.toString(),
          name: _spec.primaryValues[index],
        ),
    ];
    _selectedParentId = _primaryEntries.first.id;
    _secondaryEntries = [
      for (var index = 0; index < _spec.secondaryValues.length; index++)
        _ManagementEntry(
          id: 'secondary-' + index.toString(),
          name: _spec.secondaryValues[index],
          parentId: _primaryEntries[
                  index.clamp(0, _primaryEntries.length - 1).toInt()]
              .id,
        ),
    ];
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  void _commitPrimary() {
    final value = _primaryController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      if (_editingPrimaryId == null) {
        _primaryEntries.add(
          _ManagementEntry(
            id: 'primary-' + (_seed++).toString(),
            name: value,
          ),
        );
      } else {
        final index = _primaryEntries.indexWhere(
          (entry) => entry.id == _editingPrimaryId,
        );
        if (index >= 0) {
          _primaryEntries[index] =
              _primaryEntries[index].copyWith(name: value);
        }
      }
      _editingPrimaryId = null;
      _primaryController.clear();
    });
  }

  void _editPrimary(_ManagementEntry entry) {
    setState(() {
      _editingPrimaryId = entry.id;
      _primaryController.text = entry.name;
      _primaryController.selection = TextSelection.collapsed(
        offset: _primaryController.text.length,
      );
    });
  }

  void _deletePrimary(_ManagementEntry entry) {
    if (_primaryEntries.length == 1) return;

    setState(() {
      _primaryEntries.removeWhere((item) => item.id == entry.id);
      _secondaryEntries.removeWhere(
        (item) => item.parentId == entry.id,
      );
      if (_selectedParentId == entry.id) {
        _selectedParentId = _primaryEntries.first.id;
      }
      if (_editingPrimaryId == entry.id) {
        _editingPrimaryId = null;
        _primaryController.clear();
      }
    });
  }

  void _commitSecondary() {
    final value = _secondaryController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      if (_editingSecondaryId == null) {
        _secondaryEntries.add(
          _ManagementEntry(
            id: 'secondary-' + (_seed++).toString(),
            name: value,
            parentId: _selectedParentId,
          ),
        );
      } else {
        final index = _secondaryEntries.indexWhere(
          (entry) => entry.id == _editingSecondaryId,
        );
        if (index >= 0) {
          _secondaryEntries[index] = _secondaryEntries[index].copyWith(
            name: value,
            parentId: _selectedParentId,
          );
        }
      }
      _editingSecondaryId = null;
      _secondaryController.clear();
    });
  }

  void _editSecondary(_ManagementEntry entry) {
    setState(() {
      _editingSecondaryId = entry.id;
      _secondaryController.text = entry.name;
      _secondaryController.selection = TextSelection.collapsed(
        offset: _secondaryController.text.length,
      );
    });
  }

  void _deleteSecondary(_ManagementEntry entry) {
    setState(() {
      _secondaryEntries.removeWhere((item) => item.id == entry.id);
      if (_editingSecondaryId == entry.id) {
        _editingSecondaryId = null;
        _secondaryController.clear();
      }
    });
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
      actionsKey: Key(_spec.keyName + 'Actions'),
      actions: [
        AppButton(
          key: Key(_spec.keyName + 'Cancel'),
          label: 'إغلاق',
          variant: AppButtonVariant.secondary,
          width: 144,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          key: Key(_spec.keyName + 'Confirm'),
          label: 'حفظ',
          icon: Icons.save_rounded,
          width: 144,
          backgroundColor: _spec.accentColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildPrimarySection()),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildSecondarySection()),
        ],
      ),
    );
  }

  Widget _buildPrimarySection() {
    return AppDialogSection(
      title: _spec.primaryTitle,
      icon: Icons.folder_rounded,
      accentColor: _spec.accentColor,
      child: Column(
        children: [
          _ManagementEditor(
            fieldKey: Key(_spec.keyName + 'PrimaryField'),
            buttonKey: Key(_spec.keyName + 'PrimaryCommit'),
            controller: _primaryController,
            label: _spec.primaryFieldLabel,
            accentColor: _spec.accentColor,
            editing: _editingPrimaryId != null,
            onCommit: _commitPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          _ManagementEntries(
            entries: _primaryEntries,
            keyPrefix: _spec.keyName + 'Primary',
            accentColor: _spec.accentColor,
            selectedId: _selectedParentId,
            onSelected: (entry) {
              setState(() {
                _selectedParentId = entry.id;
                _editingSecondaryId = null;
                _secondaryController.clear();
              });
            },
            onEdit: _editPrimary,
            onDelete: _deletePrimary,
            canDelete: _primaryEntries.length > 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondarySection() {
    return AppDialogSection(
      title: _spec.secondaryTitle,
      icon: Icons.account_tree_rounded,
      accentColor: _spec.accentColor,
      child: Column(
        children: [
          AppDropdownField<String>(
            fieldKey: Key(_spec.keyName + 'ParentDropdown'),
            label: _spec.primaryTitle,
            icon: Icons.link_rounded,
            accentColor: _spec.accentColor,
            value: _selectedParentId,
            options: [
              for (final entry in _primaryEntries)
                AppDropdownOption(value: entry.id, label: entry.name),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedParentId = value;
                _editingSecondaryId = null;
                _secondaryController.clear();
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _ManagementEditor(
            fieldKey: Key(_spec.keyName + 'SecondaryField'),
            buttonKey: Key(_spec.keyName + 'SecondaryCommit'),
            controller: _secondaryController,
            label: _spec.secondaryFieldLabel,
            accentColor: _spec.accentColor,
            editing: _editingSecondaryId != null,
            onCommit: _commitSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          _ManagementEntries(
            entries: _visibleSecondaryEntries,
            keyPrefix: _spec.keyName + 'Secondary',
            accentColor: _spec.accentColor,
            onEdit: _editSecondary,
            onDelete: _deleteSecondary,
          ),
        ],
      ),
    );
  }
}

class _ManagementEditor extends StatelessWidget {
  const _ManagementEditor({
    required this.fieldKey,
    required this.buttonKey,
    required this.controller,
    required this.label,
    required this.accentColor,
    required this.editing,
    required this.onCommit,
  });

  final Key fieldKey;
  final Key buttonKey;
  final TextEditingController controller;
  final String label;
  final Color accentColor;
  final bool editing;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            fieldKey: fieldKey,
            controller: controller,
            label: label,
            icon: editing ? Icons.edit_rounded : Icons.add_rounded,
            accentColor: accentColor,
            onSubmitted: (_) => onCommit(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          key: buttonKey,
          label: editing ? 'تحديث' : 'إضافة',
          icon: editing ? Icons.update_rounded : Icons.add_rounded,
          width: 112,
          backgroundColor: accentColor,
          onPressed: onCommit,
        ),
      ],
    );
  }
}

class _ManagementEntries extends StatelessWidget {
  const _ManagementEntries({
    required this.entries,
    required this.keyPrefix,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
    this.selectedId,
    this.onSelected,
    this.canDelete = true,
  });

  final List<_ManagementEntry> entries;
  final String keyPrefix;
  final Color accentColor;
  final String? selectedId;
  final ValueChanged<_ManagementEntry>? onSelected;
  final ValueChanged<_ManagementEntry> onEdit;
  final ValueChanged<_ManagementEntry> onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const AppEmptyState(
        title: 'لا توجد بيانات',
        message: 'اكتب الاسم ثم اضغط إضافة.',
        icon: Icons.inbox_rounded,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _ManagementEntryTile(
            key: Key(keyPrefix + 'Row-' + entries[index].id),
            entry: entries[index],
            accentColor: accentColor,
            selected: entries[index].id == selectedId,
            onSelected: onSelected == null
                ? null
                : () => onSelected!(entries[index]),
            editKey: Key(keyPrefix + 'Edit-' + entries[index].id),
            deleteKey: Key(keyPrefix + 'Delete-' + entries[index].id),
            onEdit: () => onEdit(entries[index]),
            onDelete:
                canDelete ? () => onDelete(entries[index]) : null,
          ),
        ],
      ],
    );
  }
}

class _ManagementEntryTile extends StatelessWidget {
  const _ManagementEntryTile({
    required this.entry,
    required this.accentColor,
    required this.selected,
    required this.editKey,
    required this.deleteKey,
    required this.onEdit,
    required this.onDelete,
    this.onSelected,
    super.key,
  });

  final _ManagementEntry entry;
  final Color accentColor;
  final bool selected;
  final Key editKey;
  final Key deleteKey;
  final VoidCallback? onSelected;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Color.alphaBlend(accentColor.withAlpha(18), AppColors.surface)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onSelected,
        mouseCursor: onSelected == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        splashFactory: NoSplash.splashFactory,
        overlayColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? accentColor : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 9, color: accentColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(entry.name, style: AppTypography.tableCell),
              ),
              AppTableActionButton(
                key: editKey,
                icon: Icons.edit_rounded,
                tooltip: 'تعديل',
                onPressed: onEdit,
              ),
              const SizedBox(width: AppSpacing.xs),
              AppTableActionButton(
                key: deleteKey,
                icon: Icons.delete_rounded,
                tooltip: 'حذف',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class _ManagementEntry {
  const _ManagementEntry({
    required this.id,
    required this.name,
    this.parentId,
  });

  final String id;
  final String name;
  final String? parentId;

  _ManagementEntry copyWith({
    String? name,
    String? parentId,
  }) {
    return _ManagementEntry(
      id: id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
    );
  }
}
