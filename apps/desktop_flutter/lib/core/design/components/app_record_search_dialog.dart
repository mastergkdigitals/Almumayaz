import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_module_dialog.dart';
import 'app_text_fields.dart';

@immutable
class AppSearchRecord<T extends Object> {
  const AppSearchRecord({
    required this.value,
    required this.title,
    this.subtitle,
    this.details,
    this.searchTerms = const [],
    this.icon = Icons.receipt_long_outlined,
  });

  final T value;
  final String title;
  final String? subtitle;
  final String? details;
  final List<String> searchTerms;
  final IconData icon;
}

abstract final class AppRecordSearchDialog {
  static Future<T?> show<T extends Object>(
    BuildContext context, {
    required String title,
    required String hint,
    required Color accentColor,
    required List<AppSearchRecord<T>> records,
    String subtitle = 'اكتب للبحث ثم اختر السجل المطلوب',
    String searchLabel = 'بحث',
    String emptyTitle = 'لا توجد سجلات محفوظة',
    String noResultsTitle = 'لا توجد نتائج مطابقة',
    Key dialogKey = const Key('appRecordSearchDialog'),
    Key searchFieldKey = const Key('appRecordSearchField'),
    String resultKeyPrefix = 'appRecordSearchResult',
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _AppRecordSearchDialog<T>(
          dialogKey: dialogKey,
          searchFieldKey: searchFieldKey,
          resultKeyPrefix: resultKeyPrefix,
          title: title,
          subtitle: subtitle,
          searchLabel: searchLabel,
          hint: hint,
          accentColor: accentColor,
          records: records,
          emptyTitle: emptyTitle,
          noResultsTitle: noResultsTitle,
        ),
      ),
    );
  }
}

class _AppRecordSearchDialog<T extends Object> extends StatefulWidget {
  const _AppRecordSearchDialog({
    required this.dialogKey,
    required this.searchFieldKey,
    required this.resultKeyPrefix,
    required this.title,
    required this.subtitle,
    required this.searchLabel,
    required this.hint,
    required this.accentColor,
    required this.records,
    required this.emptyTitle,
    required this.noResultsTitle,
  });

  final Key dialogKey;
  final Key searchFieldKey;
  final String resultKeyPrefix;
  final String title;
  final String subtitle;
  final String searchLabel;
  final String hint;
  final Color accentColor;
  final List<AppSearchRecord<T>> records;
  final String emptyTitle;
  final String noResultsTitle;

  @override
  State<_AppRecordSearchDialog<T>> createState() =>
      _AppRecordSearchDialogState<T>();
}

class _AppRecordSearchDialogState<T extends Object>
    extends State<_AppRecordSearchDialog<T>> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'recordSearch');

  List<AppSearchRecord<T>> get _matches {
    final query = _normalizeSearchText(_searchController.text);
    if (query.isEmpty) return widget.records;

    return widget.records.where((record) {
      final values = [
        record.title,
        if (record.subtitle != null) record.subtitle!,
        if (record.details != null) record.details!,
        ...record.searchTerms,
      ];
      return values.any(
        (value) => _normalizeSearchText(value).contains(query),
      );
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _selectFirstMatch() {
    final matches = _matches;
    if (matches.isNotEmpty) {
      Navigator.of(context).pop(matches.first.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return AppModuleDialog(
      key: widget.dialogKey,
      title: widget.title,
      subtitle: widget.subtitle,
      icon: Icons.search_rounded,
      accentColor: widget.accentColor,
      centerHeader: true,
      showHeaderCloseButton: true,
      width: 760,
      onClose: () => Navigator.of(context).pop(),
      child: SizedBox(
        height: 430,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchField(
              fieldKey: widget.searchFieldKey,
              controller: _searchController,
              focusNode: _searchFocusNode,
              label: widget.searchLabel,
              hint: widget.hint,
              accentColor: widget.accentColor,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _selectFirstMatch(),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    widget.accentColor.withAlpha(7),
                    AppColors.surface,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: Color.alphaBlend(
                      widget.accentColor.withAlpha(72),
                      AppColors.border,
                    ),
                  ),
                ),
                child: matches.isEmpty
                    ? _SearchEmptyState(
                        accentColor: widget.accentColor,
                        title: widget.records.isEmpty
                            ? widget.emptyTitle
                            : widget.noResultsTitle,
                        message: hasQuery && widget.records.isNotEmpty
                            ? 'جرّب كتابة اسم أو رقم آخر'
                            : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        itemCount: matches.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final record = matches[index];
                          return _SearchResultTile<T>(
                            key: Key(
                              '${widget.resultKeyPrefix}-$index',
                            ),
                            record: record,
                            accentColor: widget.accentColor,
                            onSelected: () =>
                                Navigator.of(context).pop(record.value),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile<T extends Object> extends StatelessWidget {
  const _SearchResultTile({
    required this.record,
    required this.accentColor,
    required this.onSelected,
    super.key,
  });

  final AppSearchRecord<T> record;
  final Color accentColor;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onSelected,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(AppRadii.md),
        hoverColor: Color.alphaBlend(
          accentColor.withAlpha(12),
          AppColors.surface,
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    accentColor.withAlpha(20),
                    AppColors.surface,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(record.icon, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.fieldText.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (record.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (record.details != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.details!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_left_rounded,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.accentColor,
    required this.title,
    this.message,
  });

  final Color accentColor;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: accentColor,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _normalizeSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ة', 'ه');
}
