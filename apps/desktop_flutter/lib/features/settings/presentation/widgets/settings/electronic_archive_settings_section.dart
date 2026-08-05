part of '../settings_sections.dart';

class ElectronicArchiveSettingsSection extends StatefulWidget {
  const ElectronicArchiveSettingsSection({
    required this.accentColor,
    super.key,
    this.securityService,
    this.repository,
    this.validationPolicy,
  });

  final Color accentColor;
  final ArchiveSecurityService? securityService;
  final ArchiveRepository? repository;
  final ArchiveValidationPolicy? validationPolicy;

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
  var _isLoading = true;
  String? _loadError;
  final _documents = <_ArchiveDocument>[
    const _ArchiveDocument(
      id: 1,
      name: 'عقد تجهيز شركة النور',
      type: 'PDF',
      fileName: 'noor_contract.pdf',
      size: '1.8 MB',
      createdAt: '2026/07/29',
    ),
    const _ArchiveDocument(
      id: 2,
      name: 'وصل استلام المخزن الرئيسي',
      type: 'PNG',
      fileName: 'warehouse_receipt.png',
      size: '640 KB',
      createdAt: '2026/07/28',
    ),
    const _ArchiveDocument(
      id: 3,
      name: 'اتفاقية الزبون أحمد كريم',
      type: 'PDF',
      fileName: 'customer_agreement.pdf',
      size: '2.1 MB',
      createdAt: '2026/07/26',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _securityService =
        widget.securityService ?? DemoArchiveSecurityService();
    _repository = widget.repository ?? DemoArchiveRepository();
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

  Future<void> _openUploadDialog() async {
    final draft = await showDialog<_ArchiveDocumentDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ArchiveUploadDialog(
          accentColor: widget.accentColor,
          securityService: _securityService,
          validationPolicy: _validationPolicy,
        ),
      ),
    );
    if (draft == null || !mounted) return;

    try {
      final document = await _repository.upload(
        ArchiveUploadRequest(
          draft: ArchiveDocumentDraft(
            displayName: draft.name,
            file: draft.file,
          ),
          securityReport: draft.securityReport,
        ),
      );
      if (!mounted) return;
      setState(() {
        _documents.insert(0, _archiveDocumentFromDomain(document));
      });
      AppToast.showSuccess(
        context,
        'تم رفع الملف بعد نتيجة فحص خادم تجريبية نظيفة',
      );
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
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
      final renamed = await _repository.rename(document.domainId, name);
      if (!mounted) return;
      setState(() {
        _documents[index] = _archiveDocumentFromDomain(renamed);
      });
      AppToast.showSuccess(context, 'تم تعديل اسم الملف');
    } on Object catch (error) {
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
      final decision = await _repository.canDelete(document.domainId);
      if (!decision.isAllowed) {
        throw ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          message: decision.reason ?? 'لا يمكن حذف المستند',
        );
      }
      await _repository.delete(document.domainId);
      if (!mounted) return;
      setState(() {
        _documents.removeWhere((entry) => entry.id == document.id);
      });
      AppToast.showDanger(context, 'تم حذف الملف التجريبي');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _viewDocument(_ArchiveDocument document) async {
    try {
      final source = await _repository.preparePreview(document.domainId);
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
              'الأرشيف التجريبي يقبل PDF وPNG فقط. فحص الجهاز تمهيدي وغير حاسم؛ '
              'لا يُتاح الرفع إلا بعد نتيجة فحص خادم موثوقة مُحاكاة بوضوح.',
          icon: Icons.inventory_2_outlined,
          foregroundColor: widget.accentColor,
          backgroundColor: Color.alphaBlend(
            widget.accentColor.withAlpha(18),
            AppColors.surface,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsTemplatePanel(
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
                  AppTableColumn(label: 'اسم الملف', flex: 1.5),
                  AppTableColumn(label: 'النوع', flex: 0.65),
                  AppTableColumn(label: 'الحجم', flex: 0.7),
                  AppTableColumn(label: 'تاريخ الإضافة', flex: 1),
                  AppTableColumn(label: 'الإجراءات', flex: 1.15),
                ],
                rows: [
                  for (final document in filteredDocuments)
                    AppTableRow(
                      rowKey:
                          Key('settingsArchiveRow_${document.id}'),
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
                                  'settingsArchiveView_${document.id}',
                                ),
                                icon: Icons.visibility_outlined,
                                tooltip: 'معاينة',
                                onPressed: () =>
                                    _viewDocument(document),
                              ),
                              AppTableActionButton(
                                key: Key(
                                  'settingsArchiveRename_${document.id}',
                                ),
                                icon: Icons.drive_file_rename_outline,
                                tooltip: 'تعديل الاسم',
                                variant: AppButtonVariant.success,
                                onPressed: () =>
                                    _renameDocument(document),
                              ),
                              AppTableActionButton(
                                key: Key(
                                  'settingsArchiveDelete_${document.id}',
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

class _ArchiveDocument {
  const _ArchiveDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.fileName,
    required this.size,
    required this.createdAt,
    this.checksum = 'demo-checksum',
  });

  final int id;
  final String name;
  final String type;
  final String fileName;
  final String size;
  final String createdAt;
  final String checksum;

  EntityId get domainId => EntityId.demo('archive', id);

  _ArchiveDocument copyWith({String? name}) {
    return _ArchiveDocument(
      id: id,
      name: name ?? this.name,
      type: type,
      fileName: fileName,
      size: size,
      createdAt: createdAt,
      checksum: checksum,
    );
  }
}

_ArchiveDocument _archiveDocumentFromDomain(ArchiveDocument document) {
  return _ArchiveDocument(
    id: int.tryParse(document.id.value.split('-').last) ??
        document.id.value.hashCode.abs(),
    name: document.displayName,
    type: document.fileType == ArchiveFileType.pdf ? 'PDF' : 'PNG',
    fileName: document.originalFileName,
    size: _formatByteSize(document.byteSize),
    createdAt: _formatAuditTimestamp(document.createdAt),
    checksum: document.checksumSha256,
  );
}

class _ArchivePreviewDialog extends StatelessWidget {
  const _ArchivePreviewDialog({
    required this.document,
    required this.source,
    required this.accentColor,
  });

  final _ArchiveDocument document;
  final ArchivePreviewSource source;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('settingsArchivePreviewDialog'),
      title: 'معاينة ${document.name}',
      subtitle: 'معاينة تجريبية للنسخة المحلية المُدارة للقراءة فقط',
      icon: Icons.preview_outlined,
      accentColor: accentColor,
      onClose: () => Navigator.of(context).pop(),
      width: 720,
      actions: [
        AppButton(
          key: const Key('settingsArchivePreviewCloseButton'),
          label: 'إغلاق',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 140,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.neutralSurface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: accentColor.withAlpha(80)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  source.fileType == ArchiveFileType.pdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  size: 64,
                  color: accentColor,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(document.fileName, style: AppTypography.fieldText),
                const SizedBox(height: AppSpacing.xs),
                const Text('محتوى معاينة توضيحي — لا يوجد وصول حقيقي للملف'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'المصدر المُدار: ${source.localPath}\n'
            'الحجم: ${document.size}\n'
            'checksum: ${document.checksum}',
            key: const Key('settingsArchivePreviewMetadata'),
            textDirection: TextDirection.ltr,
            style: AppTypography.tableCell,
          ),
        ],
      ),
    );
  }
}

class _ArchiveDocumentDraft {
  const _ArchiveDocumentDraft({
    required this.name,
    required this.type,
    required this.fileName,
    required this.file,
    required this.securityReport,
  });

  final String name;
  final String type;
  final String fileName;
  final ArchiveFileCandidate file;
  final ArchiveSecurityReport securityReport;
}

class _ArchiveUploadDialog extends StatefulWidget {
  const _ArchiveUploadDialog({
    required this.accentColor,
    required this.securityService,
    required this.validationPolicy,
  });

  final Color accentColor;
  final ArchiveSecurityService securityService;
  final ArchiveValidationPolicy validationPolicy;

  @override
  State<_ArchiveUploadDialog> createState() =>
      _ArchiveUploadDialogState();
}

class _ArchiveUploadDialogState extends State<_ArchiveUploadDialog> {
  final _nameController = TextEditingController();
  final _fileController =
      TextEditingController(text: 'لم يتم اختيار ملف');
  var _type = 'PDF';
  var _fileName = '';
  ArchiveFileCandidate? _file;
  ArchiveSecurityReport? _localReport;
  ArchiveSecurityReport? _authoritativeReport;
  String? _scanFailureMessage;
  var _isScanning = false;

  bool get _canUpload =>
      _nameController.text.trim().isNotEmpty &&
      _fileName.isNotEmpty &&
      _authoritativeReport?.isUploadAllowed == true &&
      !_isScanning;

  @override
  void dispose() {
    _nameController.dispose();
    _fileController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _chooseFile() async {
    final type = _type == 'PDF' ? ArchiveFileType.pdf : ArchiveFileType.png;
    final fileName = _type == 'PDF'
        ? 'document_example.pdf'
        : 'image_example.png';
    final file = ArchiveFileCandidate(
      localPath: 'C:\\Almumayaz\\DemoUpload\\$fileName',
      fileName: fileName,
      byteSize: _type == 'PDF' ? 1258291 : 737280,
      declaredMimeType: type.mimeType,
    );
    setState(() {
      _fileName = fileName;
      _fileController.text = _fileName;
      _file = file;
      _localReport = null;
      _authoritativeReport = null;
      _scanFailureMessage = null;
      _isScanning = true;
    });
    try {
      final localReport = await widget.securityService.validateLocally(
        file: file,
        policy: widget.validationPolicy,
      );
      if (!mounted) return;
      setState(() => _localReport = localReport);
      if (localReport.issues.isNotEmpty) return;
      final authoritative =
          await widget.securityService.scanAuthoritatively(
        file: file,
        policy: widget.validationPolicy,
      );
      if (!mounted) return;
      setState(() => _authoritativeReport = authoritative);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _scanFailureMessage = _serviceMessage(error));
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _upload() {
    if (!_canUpload) return;
    final file = _file!;
    final report = _authoritativeReport!;
    Navigator.of(context).pop(
      _ArchiveDocumentDraft(
        name: _nameController.text.trim(),
        type: _type,
        fileName: _fileName,
        file: file,
        securityReport: report,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('settingsArchiveUploadDialog'),
      title: 'رفع ملف إلى الأرشيف',
      subtitle: 'الاختيار والفحص والرفع كلها محاكاة داخل الذاكرة',
      icon: Icons.upload_file_rounded,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 680,
      actions: [
        AppButton(
          key: const Key('settingsArchiveUploadCancelButton'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: const Key('settingsArchiveUploadConfirmButton'),
          label: 'رفع',
          icon: Icons.upload_rounded,
          backgroundColor: widget.accentColor,
          width: 145,
          onPressed: _canUpload ? _upload : null,
        ),
      ],
      child: Column(
        children: [
          AppTextField(
            fieldKey: const Key('settingsArchiveDocumentNameField'),
            controller: _nameController,
            label: 'اسم المستند',
            icon: Icons.title_rounded,
            accentColor: widget.accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<String>(
            fieldKey: const Key('settingsArchiveFileTypeField'),
            label: 'نوع الملف',
            icon: Icons.description_outlined,
            accentColor: widget.accentColor,
            value: _type,
            options: const [
              AppDropdownOption(value: 'PDF', label: 'PDF'),
              AppDropdownOption(value: 'PNG', label: 'PNG'),
            ],
            useIntrinsicHeight: true,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            menuTextDirection: TextDirection.ltr,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _type = value;
                _fileName = '';
                _file = null;
                _localReport = null;
                _authoritativeReport = null;
                _scanFailureMessage = null;
                _fileController.text = 'لم يتم اختيار ملف';
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('settingsArchiveSelectedFileField'),
            controller: _fileController,
            label: 'الملف المحدد',
            icon: Icons.attach_file_rounded,
            accentColor: widget.accentColor,
            readOnly: true,
            enabled: false,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: AppRegularButton(
              key: const Key('settingsArchiveChooseFileButton'),
              label: 'اختيار ملف',
              icon: Icons.folder_open_rounded,
              onPressed: _chooseFile,
            ),
          ),
          if (_file != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSecurityState(),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityState() {
    final report = _authoritativeReport ?? _localReport;
    final file = _file!;
    final checksum = report?.checksumSha256;
    final issues = report?.issues ?? const <ArchiveValidationIssue>[];
    final message = _scanFailureMessage != null
        ? 'تعذر الفحص التجريبي: $_scanFailureMessage'
        : _isScanning
            ? 'جارٍ تنفيذ فحص الخادم التجريبي المُحاكى...'
            : issues.isNotEmpty
                ? issues.map((issue) => issue.message).join(' — ')
                : _authoritativeReport?.isUploadAllowed == true
                    ? 'نتيجة الخادم التجريبية المُحاكية: نظيف ومسموح بالرفع.'
                    : 'نجح الفحص المحلي التمهيدي، لكنه غير موثوق للسماح بالرفع.';
    return Column(
      key: const Key('settingsArchiveSecurityState'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInfoBanner(
          message: message,
          icon: _authoritativeReport?.isUploadAllowed == true
              ? Icons.verified_user_outlined
              : issues.isNotEmpty
                  ? Icons.gpp_bad_outlined
                  : Icons.hourglass_top_rounded,
          foregroundColor: issues.isNotEmpty
              ? AppColors.danger
              : widget.accentColor,
          backgroundColor: Color.alphaBlend(
            widget.accentColor.withAlpha(18),
            AppColors.surface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'الحجم: ${_formatByteSize(file.byteSize)} | '
          'التوقيع: ${report?.detectedMimeType ?? 'قيد الفحص'} | '
          'checksum: ${checksum == null ? 'غير متاح' : _shortChecksum(checksum)}',
          key: const Key('settingsArchiveSecurityMetadata'),
          textDirection: TextDirection.rtl,
          style: AppTypography.tableCell,
        ),
      ],
    );
  }
}

class _ArchiveRenameDialog extends StatefulWidget {
  const _ArchiveRenameDialog({
    required this.initialName,
    required this.accentColor,
  });

  final String initialName;
  final Color accentColor;

  @override
  State<_ArchiveRenameDialog> createState() =>
      _ArchiveRenameDialogState();
}

class _ArchiveRenameDialogState extends State<_ArchiveRenameDialog> {
  late final TextEditingController _nameController;

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (_canSave) Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('settingsArchiveRenameDialog'),
      title: 'تعديل اسم المستند',
      icon: Icons.drive_file_rename_outline,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 580,
      actions: [
        AppButton(
          key: const Key('settingsArchiveRenameCancelButton'),
          label: 'إلغاء',
          variant: AppButtonVariant.secondary,
          width: 140,
          onPressed: _close,
        ),
        AppButton(
          key: const Key('settingsArchiveRenameConfirmButton'),
          label: 'تحديث',
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.success,
          width: 140,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: AppTextField(
        fieldKey: const Key('settingsArchiveRenameField'),
        controller: _nameController,
        label: 'اسم المستند',
        icon: Icons.title_rounded,
        accentColor: widget.accentColor,
        autofocus: true,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _save(),
      ),
    );
  }
}
