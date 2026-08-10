import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_dialogs.dart';
import 'app_dropdown_field.dart';
import 'app_feedback.dart';
import 'app_table.dart';
import 'app_text_fields.dart';

@immutable
class AppManagementEntry {
  const AppManagementEntry({
    required this.id,
    required this.number,
    required this.name,
    this.parentId,
    this.isProtected = false,
  })  : assert(id != ''),
        assert(number > 0),
        assert(name != '');

  final String id;
  final int number;
  final String name;
  final String? parentId;
  final bool isProtected;

  AppManagementEntry copyWith({
    String? name,
    String? parentId,
    bool clearParent = false,
    bool? isProtected,
  }) {
    return AppManagementEntry(
      id: id,
      number: number,
      name: name ?? this.name,
      parentId: clearParent ? null : parentId ?? this.parentId,
      isProtected: isProtected ?? this.isProtected,
    );
  }
}

@immutable
class AppManagementEntryDraft {
  const AppManagementEntryDraft({
    required this.number,
    required this.name,
    required this.parentId,
  }) : assert(number > 0);

  final int number;
  final String name;
  final String? parentId;
}

@immutable
class AppManagementDeleteDecision {
  const AppManagementDeleteDecision.allowed()
      : isAllowed = true,
        reason = null;

  const AppManagementDeleteDecision.blocked(this.reason)
      : isAllowed = false;

  final bool isAllowed;
  final String? reason;
}

typedef AppManagementCreateCallback = Future<AppManagementEntry> Function(
  AppManagementEntryDraft draft,
);
typedef AppManagementUpdateCallback = Future<AppManagementEntry> Function(
  AppManagementEntry existing,
  AppManagementEntryDraft draft,
);
typedef AppManagementCanDeleteCallback
    = Future<AppManagementDeleteDecision> Function(
  AppManagementEntry entry,
);
typedef AppManagementDeleteCallback = Future<void> Function(
  AppManagementEntry entry,
);
typedef AppManagementErrorMessage = String Function(Object error);

@immutable
class AppManagementPanelKeys {
  const AppManagementPanelKeys({
    required this.prefix,
    this.parentFieldSuffix = 'ParentField',
    this.nameFieldSuffix = 'NameField',
    this.addButtonSuffix = 'AddButton',
    this.updateButtonSuffix = 'UpdateButton',
    this.clearButtonSuffix = 'ClearButton',
    this.tableSuffix = 'Table',
    this.rowSeparator = 'Row_',
    this.deleteSeparator = 'Delete_',
  });

  final String prefix;
  final String parentFieldSuffix;
  final String nameFieldSuffix;
  final String addButtonSuffix;
  final String updateButtonSuffix;
  final String clearButtonSuffix;
  final String tableSuffix;
  final String rowSeparator;
  final String deleteSeparator;

  Key get parentField => Key('$prefix$parentFieldSuffix');
  Key get nameField => Key('$prefix$nameFieldSuffix');
  Key get addButton => Key('$prefix$addButtonSuffix');
  Key get updateButton => Key('$prefix$updateButtonSuffix');
  Key get clearButton => Key('$prefix$clearButtonSuffix');
  Key get table => Key('$prefix$tableSuffix');
  Key row(String id) => Key('$prefix$rowSeparator$id');
  Key delete(String id) => Key('$prefix$deleteSeparator$id');
}

/// Canonical editor for small parent/child management lists.
///
/// The owner remains responsible for persistence and stable identifiers. This
/// component owns the shared selection, validation, action, confirmation and
/// table behavior used by production Settings and Design System examples.
class AppManagementPanel extends StatefulWidget {
  const AppManagementPanel({
    required this.keys,
    required this.fieldLabel,
    required this.accentColor,
    required this.entries,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    super.key,
    this.parentLabel,
    this.parentOptions = const [],
    this.referencedEntryIds = const <String>{},
    this.canDelete,
    this.errorMessage,
    this.selectedEntryId,
    this.selectedParentId,
    this.onSelectionChanged,
    this.onParentChanged,
    this.tableHeight = 270,
    this.rowHeight = 54,
    this.minimumColumnWidth = 115,
    this.showStatusColumn = true,
    this.confirmDeletion = true,
    this.deleteBlockedMessage =
        'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
    this.emptyMessage = 'اكتب الاسم ثم اضغط إضافة.',
    this.addSuccessMessage = 'تمت إضافة السجل',
    this.updateSuccessMessage = 'تم تحديث السجل',
    this.deleteSuccessMessage = 'تم حذف السجل',
  });

  final AppManagementPanelKeys keys;
  final String fieldLabel;
  final String? parentLabel;
  final Color accentColor;
  final List<AppManagementEntry> entries;
  final List<AppManagementEntry> parentOptions;
  final Set<String> referencedEntryIds;
  final AppManagementCreateCallback onCreate;
  final AppManagementUpdateCallback onUpdate;
  final AppManagementCanDeleteCallback? canDelete;
  final AppManagementDeleteCallback onDelete;
  final AppManagementErrorMessage? errorMessage;
  final String? selectedEntryId;
  final String? selectedParentId;
  final ValueChanged<AppManagementEntry?>? onSelectionChanged;
  final ValueChanged<String>? onParentChanged;
  final double tableHeight;
  final double rowHeight;
  final double minimumColumnWidth;
  final bool showStatusColumn;
  final bool confirmDeletion;
  final String deleteBlockedMessage;
  final String emptyMessage;
  final String addSuccessMessage;
  final String updateSuccessMessage;
  final String deleteSuccessMessage;

  @override
  State<AppManagementPanel> createState() => _AppManagementPanelState();
}

class _AppManagementPanelState extends State<AppManagementPanel> {
  final _nameController = TextEditingController();
  String? _selectedId;
  String? _selectedParentId;
  var _isMutating = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedEntryId;
    _selectedParentId = _initialParentId();
    final selected = _entryById(_selectedId);
    if (selected != null) _writeEntry(selected);
  }

  @override
  void didUpdateWidget(covariant AppManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final parentSelectionChanged =
        widget.selectedParentId != oldWidget.selectedParentId;
    final parentWasSelectedInternally =
        _selectedParentId == widget.selectedParentId;

    if (widget.selectedEntryId != oldWidget.selectedEntryId) {
      _selectedId = widget.selectedEntryId;
      final selected = _entryById(_selectedId);
      if (selected == null) {
        _nameController.clear();
      } else {
        _writeEntry(selected);
      }
    } else if (_selectedId != null && _entryById(_selectedId) == null) {
      _selectedId = null;
      _nameController.clear();
    }

    if (parentSelectionChanged) {
      _selectedParentId = widget.selectedParentId;
      final selected = _entryById(_selectedId);
      if (selected != null &&
          !parentWasSelectedInternally &&
          widget.parentLabel != null &&
          selected.parentId != _selectedParentId) {
        _selectedId = null;
        _nameController.clear();
      }
    }

    final selected = _entryById(_selectedId);
    if (!parentSelectionChanged &&
        selected != null &&
        widget.parentLabel != null) {
      _selectedParentId = selected.parentId;
    }
    if (widget.parentLabel == null) {
      _selectedParentId = null;
    } else if (!widget.parentOptions.any(
      (parent) => parent.id == _selectedParentId,
    )) {
      _selectedParentId = _firstEntry(widget.parentOptions)?.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _initialParentId() {
    if (widget.parentLabel == null) return null;
    final requested = widget.selectedParentId;
    if (widget.parentOptions.any((entry) => entry.id == requested)) {
      return requested;
    }
    return _firstEntry(widget.parentOptions)?.id;
  }

  AppManagementEntry? _entryById(String? id) {
    if (id == null) return null;
    for (final entry in widget.entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  void _writeEntry(AppManagementEntry entry) {
    _nameController.text = entry.name;
    _nameController.selection = TextSelection.collapsed(
      offset: _nameController.text.length,
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedId = null;
      _nameController.clear();
      _selectedParentId = _initialParentId();
    });
    widget.onSelectionChanged?.call(null);
  }

  bool _validateDraft(String name, {String? excludingId}) {
    if (name.isEmpty) {
      AppToast.showWarning(context, 'اكتب ${widget.fieldLabel} أولاً');
      return false;
    }
    if (widget.parentLabel != null && _selectedParentId == null) {
      AppToast.showWarning(context, 'اختر ${widget.parentLabel} أولاً');
      return false;
    }
    final normalized = name.toLowerCase();
    final duplicate = widget.entries.any(
      (entry) =>
          entry.id != excludingId &&
          entry.parentId == _selectedParentId &&
          entry.name.trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      AppToast.showWarning(context, 'هذا الاسم مستخدم مسبقاً');
      return false;
    }
    return true;
  }

  int _nextNumber() {
    var largest = 0;
    for (final entry in widget.entries) {
      if (entry.parentId != _selectedParentId) continue;
      if (entry.number > largest) largest = entry.number;
    }
    return largest + 1;
  }

  Future<void> _addEntry() async {
    if (_isMutating) return;
    final name = _nameController.text.trim();
    if (!_validateDraft(name)) return;
    setState(() => _isMutating = true);
    try {
      final created = await widget.onCreate(
        AppManagementEntryDraft(
          number: _nextNumber(),
          name: name,
          parentId: _selectedParentId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _selectedId = created.id;
        _selectedParentId = created.parentId;
        _writeEntry(created);
      });
      widget.onSelectionChanged?.call(created);
      AppToast.showInfo(context, widget.addSuccessMessage);
    } catch (error) {
      if (mounted) AppToast.showDanger(context, _errorMessage(error));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _updateEntry() async {
    if (_isMutating) return;
    final selected = _entryById(_selectedId);
    final name = _nameController.text.trim();
    if (selected == null) {
      AppToast.showWarning(context, 'اختر سجلاً واكتب الاسم الجديد');
      return;
    }
    if (!_validateDraft(name, excludingId: selected.id)) return;
    setState(() => _isMutating = true);
    try {
      final updated = await widget.onUpdate(
        selected,
        AppManagementEntryDraft(
          number: selected.number,
          name: name,
          parentId: _selectedParentId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _selectedId = updated.id;
        _selectedParentId = updated.parentId;
        _writeEntry(updated);
      });
      widget.onSelectionChanged?.call(updated);
      AppToast.showSuccess(context, widget.updateSuccessMessage);
    } catch (error) {
      if (mounted) AppToast.showDanger(context, _errorMessage(error));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _deleteEntry(AppManagementEntry entry) async {
    if (_isMutating) return;
    if (entry.isProtected) {
      AppToast.showDanger(context, 'لا يمكن حذف سجل نظام محمي');
      return;
    }
    if (widget.referencedEntryIds.contains(entry.id)) {
      AppToast.showDanger(context, widget.deleteBlockedMessage);
      return;
    }

    setState(() => _isMutating = true);
    try {
      final canDelete = widget.canDelete;
      final decision = canDelete == null
          ? const AppManagementDeleteDecision.allowed()
          : await canDelete(entry);
      if (!mounted) return;
      if (!decision.isAllowed) {
        AppToast.showDanger(
          context,
          decision.reason ?? widget.deleteBlockedMessage,
        );
        return;
      }

      if (widget.confirmDeletion) {
        final confirmed = await AppDialogs.confirm(
          context: context,
          title: 'حذف السجل',
          message: 'هل تريد حذف «${entry.name}»؟',
          confirmLabel: 'حذف',
          isDanger: true,
        );
        if (!confirmed || !mounted) return;
      }

      await widget.onDelete(entry);
      if (!mounted) return;
      if (_selectedId == entry.id) {
        setState(() {
          _selectedId = null;
          _nameController.clear();
        });
        widget.onSelectionChanged?.call(null);
      }
      AppToast.showDanger(context, widget.deleteSuccessMessage);
    } catch (error) {
      if (mounted) AppToast.showDanger(context, _errorMessage(error));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  String _errorMessage(Object error) {
    return widget.errorMessage?.call(error) ??
        'تعذر إكمال العملية. حاول مرة أخرى.';
  }

  void _selectEntry(AppManagementEntry entry) {
    setState(() {
      _selectedId = entry.id;
      _selectedParentId = entry.parentId;
      _writeEntry(entry);
    });
    widget.onSelectionChanged?.call(entry);
    final parentId = entry.parentId;
    if (parentId != null) widget.onParentChanged?.call(parentId);
  }

  @override
  Widget build(BuildContext context) {
    final parentNames = {
      for (final parent in widget.parentOptions) parent.id: parent.name,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.parentLabel != null) ...[
          AppDropdownField<String>(
            fieldKey: widget.keys.parentField,
            label: widget.parentLabel!,
            icon: Icons.account_tree_outlined,
            accentColor: widget.accentColor,
            value: _selectedParentId,
            enabled: widget.parentOptions.isNotEmpty && !_isMutating,
            options: [
              for (final option in widget.parentOptions)
                AppDropdownOption(value: option.id, label: option.name),
            ],
            useIntrinsicHeight: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            menuTextDirection: TextDirection.rtl,
            onChanged: (value) {
              if (value == null || value == _selectedParentId) return;
              setState(() => _selectedParentId = value);
              widget.onParentChanged?.call(value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppTextField(
          fieldKey: widget.keys.nameField,
          controller: _nameController,
          label: widget.fieldLabel,
          icon: Icons.edit_outlined,
          accentColor: widget.accentColor,
          enabled: !_isMutating,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) =>
              _selectedId == null ? _addEntry() : _updateEntry(),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          textDirection: TextDirection.rtl,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              key: widget.keys.addButton,
              label: 'إضافة',
              icon: Icons.add_rounded,
              backgroundColor: widget.accentColor,
              minWidth: 115,
              onPressed: _isMutating ||
                      (widget.parentLabel != null &&
                          _selectedParentId == null)
                  ? null
                  : _addEntry,
            ),
            AppButton(
              key: widget.keys.updateButton,
              label: 'تحديث',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.success,
              minWidth: 115,
              onPressed: _isMutating ||
                      _selectedId == null ||
                      (widget.parentLabel != null &&
                          _selectedParentId == null)
                  ? null
                  : _updateEntry,
            ),
            AppButton(
              key: widget.keys.clearButton,
              label: 'تراجع',
              icon: Icons.undo_rounded,
              variant: AppButtonVariant.warning,
              minWidth: 115,
              onPressed: _isMutating ||
                      (_selectedId == null && _nameController.text.isEmpty)
                  ? null
                  : _clearSelection,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppDataTable(
          key: widget.keys.table,
          height: widget.tableHeight,
          rowHeight: widget.rowHeight,
          minimumColumnWidth: widget.minimumColumnWidth,
          accentColor: widget.accentColor,
          showShadow: false,
          emptyState: AppStatePanel(
            type: AppStateType.empty,
            title: 'لا توجد بيانات',
            message: widget.emptyMessage,
          ),
          columns: [
            const AppTableColumn(label: 'ت', flex: 0.45, numeric: true),
            const AppTableColumn(label: 'الاسم', flex: 1.8),
            if (widget.parentLabel != null)
              AppTableColumn(label: widget.parentLabel!, flex: 1.35),
            if (widget.showStatusColumn)
              const AppTableColumn(label: 'الحالة', flex: 1),
            const AppTableColumn(label: 'الإجراءات', flex: 0.8),
          ],
          rows: [
            for (final entry in widget.entries)
              AppTableRow(
                rowKey: widget.keys.row(entry.id),
                selected: entry.id == _selectedId,
                onTap: () => _selectEntry(entry),
                cells: [
                  Text('${entry.number}', textAlign: TextAlign.center),
                  Text(entry.name, overflow: TextOverflow.ellipsis),
                  if (widget.parentLabel != null)
                    Text(
                      parentNames[entry.parentId] ?? 'غير محدد',
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (widget.showStatusColumn)
                    Center(
                      child: AppStatusBadge(
                        label: entry.isProtected ? 'نظامي' : 'نشط',
                        tone: entry.isProtected
                            ? AppStatusTone.info
                            : AppStatusTone.success,
                      ),
                    ),
                  Center(
                    child: AppTableActionButton(
                      key: widget.keys.delete(entry.id),
                      icon: Icons.delete_outline_rounded,
                      tooltip: entry.isProtected ? 'سجل نظامي' : 'حذف',
                      variant: AppButtonVariant.danger,
                      onPressed:
                          _isMutating ? null : () => _deleteEntry(entry),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

AppManagementEntry? _firstEntry(List<AppManagementEntry> entries) {
  return entries.isEmpty ? null : entries.first;
}
