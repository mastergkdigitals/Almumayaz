part of '../settings_sections.dart';

class ElectronicArchiveSettingsSection extends StatefulWidget {
  const ElectronicArchiveSettingsSection({
    required this.accentColor,
    super.key,
    this.securityService,
    this.repository,
    this.validationPolicy,
    this.fileSelectionService,
    this.auditWriter,
  });

  final Color accentColor;
  final ArchiveSecurityService? securityService;
  final ArchiveRepository? repository;
  final ArchiveValidationPolicy? validationPolicy;
  final ArchiveFileSelectionService? fileSelectionService;
  final AuditEventWriter? auditWriter;

  @override
  State<ElectronicArchiveSettingsSection> createState() =>
      _ElectronicArchiveSettingsSectionState();
}
class _ElectronicArchiveSettingsSectionState
    extends State<ElectronicArchiveSettingsSection> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'settingsArchiveSearch');
  late final ArchiveSecurityService _securityService;
  late final ArchiveRepository _repository;
  late final ArchiveValidationPolicy _validationPolicy;
  late final ArchiveFileSelectionService _fileSelectionService;
  var _isLoading = true;
  String? _loadError;
  final _documents = <_ArchiveDocument>[];

  @override
  void initState() {
    super.initState();
    _securityService =
        widget.securityService ?? DemoArchiveSecurityService();
    _repository = widget.repository ?? DemoArchiveRepository();
    _fileSelectionService = widget.fileSelectionService ??
        DemoArchiveFileSelectionService();
    _validationPolicy = widget.validationPolicy ??
        ArchiveValidationPolicy(maximumByteSize: 10 * 1024 * 1024);
    _refreshArchive(showLoading: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _writeAudit(AuditEvent event) async {
    final writer = widget.auditWriter;
    if (writer == null) return;
    try {
      await writer.write(event);
    } on Object {
      // Audit failure must not replace the archive workflow result.
      debugPrint('Archive workflow audit write failed.');
    }
  }

  Future<void> _openUploadDialog() async {
    final document = await showDialog<ArchiveDocument>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ArchiveUploadDialog(
          accentColor: widget.accentColor,
          securityService: _securityService,
          repository: _repository,
          fileSelectionService: _fileSelectionService,
          validationPolicy: _validationPolicy,
          auditWriter: widget.auditWriter,
        ),
      ),
    );
    if (document == null || !mounted) return;
    setState(() {
      _documents.insert(0, _archiveDocumentFromDomain(document));
    });
    AppToast.showSuccess(
      context,
      'تم الرفع التجريبي بعد نتيجة فحص خادم مُحاكاة نظيفة',
    );
  }

  Future<void> _renameDocument(_ArchiveDocument document) async {
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ArchiveRenameDialog(
          initialName: document.name,
          accentColor: widget.accentColor,
        ),
      ),
    );
    if (name == null || !mounted) return;

    final index = _documents.indexWhere((entry) => entry.id == document.id);
    if (index < 0) return;
    try {
      final renamed = await _repository.rename(document.id, name);
      await _writeAudit(
        AuditEvent(
          action: AuditAction.update,
          outcome: AuditOutcome.success,
          summary: 'تم تعديل اسم مستند في الأرشيف الإلكتروني',
          entityType: 'archiveDocument',
          entityId: document.id,
          before: {'displayName': document.name},
          after: {'displayName': renamed.displayName},
          details: {'fileType': document.type},
        ),
      );
      if (!mounted) return;
      setState(() {
        _documents[index] = _archiveDocumentFromDomain(renamed);
      });
      AppToast.showSuccess(context, 'تم تعديل اسم الملف');
    } on Object catch (error) {
      await _writeAudit(
        AuditEvent(
          action: AuditAction.update,
          outcome: AuditOutcome.failure,
          summary: 'فشل تعديل اسم مستند في الأرشيف الإلكتروني',
          entityType: 'archiveDocument',
          entityId: document.id,
          before: {'displayName': document.name},
          after: {'displayName': name},
          details: _auditFailureDetails(error),
        ),
      );
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _deleteDocument(_ArchiveDocument document) async {
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف ملف من الأرشيف',
      message: 'هل تريد حذف «${document.name}»؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed || !mounted) return;

    try {
      final decision = await _repository.canDelete(document.id);
      if (!decision.isAllowed) {
        throw ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          message: decision.reason ?? 'لا يمكن حذف المستند',
        );
      }
      await _repository.delete(document.id);
      await _writeAudit(
        AuditEvent(
          action: AuditAction.delete,
          outcome: AuditOutcome.success,
          summary: 'تم حذف مستند من الأرشيف الإلكتروني',
          entityType: 'archiveDocument',
          entityId: document.id,
          before: {
            'displayName': document.name,
            'fileName': document.fileName,
            'fileType': document.type,
            'checksumSha256': document.checksum,
          },
          details: const {'storage': 'demoInMemory'},
        ),
      );
      if (!mounted) return;
      setState(() {
        _documents.removeWhere((entry) => entry.id == document.id);
      });
      AppToast.showDanger(context, 'تم حذف الملف التجريبي');
    } on Object catch (error) {
      await _writeAudit(
        AuditEvent(
          action: AuditAction.delete,
          outcome: AuditOutcome.failure,
          summary: 'فشل حذف مستند من الأرشيف الإلكتروني',
          entityType: 'archiveDocument',
          entityId: document.id,
          details: _auditFailureDetails(error),
        ),
      );
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _viewDocument(_ArchiveDocument document) async {
    try {
      final source = await _repository.preparePreview(document.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: _ArchivePreviewDialog(
            document: document,
            source: source,
            accentColor: widget.accentColor,
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _refreshArchive({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final documents = await _repository.search(
        ArchiveQuery(searchText: _searchController.text),
      );
      if (!mounted) return;
      setState(() {
        _documents
          ..clear()
          ..addAll(documents.map(_archiveDocumentFromDomain));
        _isLoading = false;
        _loadError = null;
      });
    } on Object catch (error) {
      if (mounted) {
        final message = _serviceMessage(error);
        setState(() {
          _isLoading = false;
          _loadError = message;
        });
        AppToast.showError(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredDocuments = _documents.where((document) {
      final haystack =
          '${document.name} ${document.fileName} ${document.type} '
          '${document.createdAt}'
              .toLowerCase();
      return query.isEmpty || haystack.contains(query);
    }).toList();

    final content = ListView(
      key: const Key('electronicArchiveSettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (_loadError != null) ...[
          AppStatePanel(
            key: const Key('settingsArchiveLoadError'),
            type: AppStateType.error,
            title: 'تعذر تحميل الأرشيف',
            message: _loadError!,
            actionLabel: 'إعادة المحاولة',
            onAction: () => _refreshArchive(showLoading: true),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppInfoBanner(
          key: const Key('settingsArchiveInfoBanner'),
          message:
              'الأرشيف التجريبي يقبل PDF وPNG فقط. يتحقق الجهاز من التوقيع والحجم '
              'والبصمة فعلياً؛ فحص الخادم للبرمجيات الخبيثة مُحاكاة تجريبية '
              'ولا يمثل فحصاً موثوقاً فعلياً.',
          icon: Icons.inventory_2_outlined,
          foregroundColor: widget.accentColor,
          backgroundColor: Color.alphaBlend(
            widget.accentColor.withAlpha(18),
            AppColors.surface,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionPanel(
          key: const Key('settingsArchivePanel'),
          title: 'ملفات الأرشيف',
          icon: Icons.folder_copy_outlined,
          accentColor: widget.accentColor,
          actions: [
            AppRegularButton(
              key: const Key('settingsArchiveUploadButton'),
              label: 'رفع ملف',
              icon: Icons.upload_file_rounded,
              onPressed: _openUploadDialog,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                fieldKey: const Key('settingsArchiveSearchField'),
                clearButtonKey:
                    const Key('settingsArchiveSearchClearButton'),
                controller: _searchController,
                focusNode: _searchFocusNode,
                label: 'بحث في الأرشيف',
                hint: 'اسم المستند أو الملف أو النوع أو التاريخ',
                accentColor: widget.accentColor,
                onChanged: (_) => _refreshArchive(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDataTable(
                key: const Key('settingsArchiveTable'),
                height: 440,
                rowHeight: 62,
                minimumColumnWidth: 155,
                accentColor: widget.accentColor,
                showShadow: false,
                emptyState: const AppStatePanel(
                  type: AppStateType.empty,
                  title: 'لا توجد ملفات',
                  message:
                      'ارفع ملف PDF أو PNG أو غيّر عبارة البحث الحالية.',
                ),
                columns: const [
                  AppTableColumn(label: 'اسم المستند', flex: 1.8),
                  AppTableColumn(
                    label: 'اسم الملف',
                    textDirection: TextDirection.ltr,
                    flex: 1.5,
                  ),
                  AppTableColumn(label: 'النوع', flex: 0.65),
                  AppTableColumn(label: 'الحجم', numeric: true, flex: 0.7),
                  AppTableColumn(
                    label: 'تاريخ الإضافة',
                    numeric: true,
                    flex: 1,
                  ),
                  AppTableColumn(label: 'الإجراءات', flex: 1.15),
                ],
                rows: [
                  for (final document in filteredDocuments)
                    AppTableRow(
                      rowKey: Key(
                        'settingsArchiveRow_'
                        '${_archiveWidgetId(document.id)}',
                      ),
                      onTap: () => _viewDocument(document),
                      cells: [
                        Text(
                          document.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          document.fileName,
                          textDirection: TextDirection.ltr,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Center(
                          child: AppStatusBadge(
                            label: document.type,
                            tone: document.type == 'PDF'
                                ? AppStatusTone.danger
                                : AppStatusTone.info,
                          ),
                        ),
                        Text(
                          document.size,
                          textDirection: TextDirection.ltr,
                        ),
                        Text(document.createdAt),
                        Center(
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            children: [
                              AppTableActionButton(
                                key: Key(
                                  'settingsArchiveView_'
                                  '${_archiveWidgetId(document.id)}',
                                ),
                                icon: Icons.visibility_outlined,
                                tooltip: 'معاينة',
                                onPressed: () =>
                                    _viewDocument(document),
                              ),
                              AppTableActionButton(
                                key: Key(
                                  'settingsArchiveRename_'
                                  '${_archiveWidgetId(document.id)}',
                                ),
                                icon: Icons.drive_file_rename_outline,
                                tooltip: 'تعديل الاسم',
                                variant: AppButtonVariant.success,
                                onPressed: () =>
                                    _renameDocument(document),
                              ),
                              AppTableActionButton(
                                key: Key(
                                  'settingsArchiveDelete_'
                                  '${_archiveWidgetId(document.id)}',
                                ),
                                icon: Icons.delete_outline_rounded,
                                tooltip: 'حذف',
                                variant: AppButtonVariant.danger,
                                onPressed: () =>
                                    _deleteDocument(document),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return AppShortcutScope(
      onSearch: _searchFocusNode.requestFocus,
      child: AppLoadingOverlay(
        key: const Key('settingsArchiveLoadingOverlay'),
        isLoading: _isLoading,
        message: 'جاري تحميل الأرشيف',
        child: content,
      ),
    );
  }
}
