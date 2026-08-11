part of '../settings_sections.dart';

class _ArchiveDocument {
  const _ArchiveDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.fileName,
    required this.size,
    required this.createdAt,
    required this.checksum,
  });

  final EntityId id;
  final String name;
  final String type;
  final String fileName;
  final String size;
  final String createdAt;
  final String checksum;
}

_ArchiveDocument _archiveDocumentFromDomain(ArchiveDocument document) {
  return _ArchiveDocument(
    id: document.id,
    name: document.displayName,
    type: document.fileType == ArchiveFileType.pdf ? 'PDF' : 'PNG',
    fileName: document.originalFileName,
    size: _formatByteSize(document.byteSize),
    createdAt: _formatAuditTimestamp(document.createdAt),
    checksum: document.checksumSha256,
  );
}

String _archiveWidgetId(EntityId id) => id.value;

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

class _ArchiveUploadDialog extends StatefulWidget {
  const _ArchiveUploadDialog({
    required this.accentColor,
    required this.securityService,
    required this.repository,
    required this.fileSelectionService,
    required this.validationPolicy,
    this.auditWriter,
  });

  final Color accentColor;
  final ArchiveSecurityService securityService;
  final ArchiveRepository repository;
  final ArchiveFileSelectionService fileSelectionService;
  final ArchiveValidationPolicy validationPolicy;
  final AuditEventWriter? auditWriter;

  @override
  State<_ArchiveUploadDialog> createState() =>
      _ArchiveUploadDialogState();
}

class _ArchiveUploadDialogState extends State<_ArchiveUploadDialog> {
  final _nameController = TextEditingController();
  final _fileController =
      TextEditingController(text: 'لم يتم اختيار ملف');
  final _typeController = TextEditingController(text: 'غير محدد');
  var _fileName = '';
  ArchiveFileCandidate? _file;
  ArchiveSecurityReport? _localReport;
  ArchiveSecurityReport? _authoritativeReport;
  String? _scanFailureMessage;
  String? _uploadFailureMessage;
  ArchiveUploadProgress? _uploadProgress;
  var _isScanning = false;
  var _isUploading = false;

  bool get _canUpload =>
      _nameController.text.trim().isNotEmpty &&
      _fileName.isNotEmpty &&
      _authoritativeReport?.isUploadAllowed == true &&
      _authoritativeReport?.candidateBindingSha256 ==
          _file?.contentBindingSha256 &&
      _authoritativeReport?.checksumSha256 ==
          _file?.contentChecksumSha256 &&
      _authoritativeReport?.detectedFileType ==
          _file?.signatureFileType &&
      !_isScanning &&
      !_isUploading;

  @override
  void dispose() {
    _nameController.dispose();
    _fileController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _writeAudit(AuditEvent event) async {
    final writer = widget.auditWriter;
    if (writer == null) return;
    try {
      await writer.write(event);
    } on Object {
      // Audit failure must not replace selection, validation, or upload state.
      debugPrint('Archive upload audit write failed.');
    }
  }

  Future<void> _chooseFile() async {
    if (_isScanning || _isUploading) return;
    setState(() {
      _fileName = '';
      _fileController.text = 'جارٍ اختيار الملف...';
      _typeController.text = 'قيد الفحص';
      _file = null;
      _localReport = null;
      _authoritativeReport = null;
      _scanFailureMessage = null;
      _uploadFailureMessage = null;
      _uploadProgress = null;
      _isScanning = true;
    });
    try {
      final file = await widget.fileSelectionService.selectFile(
        policy: widget.validationPolicy,
      );
      if (!mounted) return;
      if (file == null) {
        setState(() {
          _fileController.text = 'لم يتم اختيار ملف';
          _typeController.text = 'غير محدد';
        });
        return;
      }
      setState(() {
        _file = file;
        _fileName = file.fileName;
        _fileController.text = file.fileName;
      });
      final localReport = await widget.securityService.validateLocally(
        file: file,
        policy: widget.validationPolicy,
      );
      if (!mounted) return;
      setState(() {
        _localReport = localReport;
        _typeController.text = _archiveFileTypeLabel(
          localReport.detectedFileType,
        );
      });
      if (localReport.issues.isNotEmpty) {
        await _writeAudit(
          AuditEvent(
            action: AuditAction.create,
            outcome: AuditOutcome.blocked,
            summary: 'رُفض ملف الأرشيف في التحقق المحلي',
            details: {
              'fileName': file.fileName,
              'byteSize': file.byteSize,
              'issues': [
                for (final issue in localReport.issues) issue.code.name,
              ],
            },
          ),
        );
        if (!mounted) return;
        AppToast.showError(context, _archiveRejectionMessage(localReport));
        return;
      }
      final authoritative =
          await widget.securityService.scanAuthoritatively(
        file: file,
        policy: widget.validationPolicy,
      );
      if (!mounted) return;
      setState(() => _authoritativeReport = authoritative);
      if (authoritative.candidateBindingSha256 !=
              file.contentBindingSha256 ||
          authoritative.checksumSha256 != file.contentChecksumSha256 ||
          authoritative.detectedFileType != file.signatureFileType) {
        await _writeAudit(
          AuditEvent(
            action: AuditAction.create,
            outcome: AuditOutcome.blocked,
            summary: 'رُفض ملف الأرشيف لعدم تطابق نتيجة الفحص',
            details: {
              'fileName': file.fileName,
              'byteSize': file.byteSize,
              'reason': 'securityReportBindingMismatch',
            },
          ),
        );
        if (!mounted) return;
        AppToast.showError(
          context,
          'رُفض الملف لأن نتيجة الفحص لا تطابق الملف المحدد',
        );
      } else if (!authoritative.isUploadAllowed) {
        await _writeAudit(
          AuditEvent(
            action: AuditAction.create,
            outcome: AuditOutcome.blocked,
            summary: 'رُفض ملف الأرشيف في فحص الخادم التجريبي',
            details: {
              'fileName': file.fileName,
              'byteSize': file.byteSize,
              'scanStatus': authoritative.scanStatus.name,
              'issues': [
                for (final issue in authoritative.issues) issue.code.name,
              ],
            },
          ),
        );
        if (!mounted) return;
        AppToast.showError(
          context,
          _archiveRejectionMessage(authoritative),
        );
      }
    } on Object catch (error) {
      await _writeAudit(
        AuditEvent(
          action: AuditAction.create,
          outcome: AuditOutcome.failure,
          summary: 'تعذر اختيار ملف الأرشيف أو فحصه',
          details: {
            if (_file != null) 'fileName': _file!.fileName,
            ..._auditFailureDetails(error),
          },
        ),
      );
      if (mounted) {
        final message = _serviceMessage(error);
        setState(() {
          _scanFailureMessage = message;
          if (_file == null) {
            _fileController.text = 'تعذر اختيار الملف';
            _typeController.text = 'غير متاح';
          }
        });
        AppToast.showError(context, message);
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _upload() async {
    if (!_canUpload) return;
    final file = _file!;
    final report = _authoritativeReport!;
    setState(() {
      _isUploading = true;
      _uploadFailureMessage = null;
      _uploadProgress = ArchiveUploadProgress(
        stage: ArchiveUploadStage.queued,
        fraction: 0,
        message: 'جارٍ تجهيز الرفع التجريبي...',
      );
    });
    try {
      final document = await widget.repository.upload(
        ArchiveUploadRequest(
          draft: ArchiveDocumentDraft(
            displayName: _nameController.text.trim(),
            file: file,
          ),
          securityReport: report,
        ),
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );
      await _writeAudit(
        AuditEvent(
          action: AuditAction.create,
          outcome: AuditOutcome.success,
          summary: 'تم رفع مستند إلى الأرشيف الإلكتروني التجريبي',
          entityType: 'archiveDocument',
          entityId: document.id,
          after: {
            'displayName': document.displayName,
            'fileName': document.originalFileName,
            'fileType': document.fileType.name,
            'byteSize': document.byteSize,
            'checksumSha256': document.checksumSha256,
          },
          details: const {'storage': 'demoInMemory'},
        ),
      );
      if (mounted) Navigator.of(context).pop(document);
    } on Object catch (error) {
      await _writeAudit(
        AuditEvent(
          action: AuditAction.create,
          outcome: AuditOutcome.failure,
          summary: 'فشل رفع مستند إلى الأرشيف الإلكتروني التجريبي',
          details: {
            'fileName': file.fileName,
            'byteSize': file.byteSize,
            ..._auditFailureDetails(error),
          },
        ),
      );
      if (!mounted) return;
      final message = error is ArgumentError
          ? 'رُفض الملف لأن نتيجة الفحص لا تطابق الملف المحدد'
          : _serviceMessage(error);
      setState(() {
        _uploadFailureMessage = message;
        _uploadProgress = ArchiveUploadProgress(
          stage: ArchiveUploadStage.failed,
          fraction: _uploadProgress?.fraction ?? 0,
          message: message,
        );
      });
      AppToast.showError(context, message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('settingsArchiveUploadDialog'),
      title: 'رفع ملف إلى الأرشيف',
      subtitle: 'الاختيار والتحقق محليان؛ فحص الخادم والرفع محاكاة تجريبية',
      icon: Icons.upload_file_rounded,
      accentColor: widget.accentColor,
      onClose: _isUploading ? () {} : _close,
      width: 680,
      actions: [
        AppButton(
          key: const Key('settingsArchiveUploadCancelButton'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _isUploading ? null : _close,
        ),
        AppButton(
          key: const Key('settingsArchiveUploadConfirmButton'),
          label: _uploadFailureMessage == null ? 'رفع' : 'إعادة المحاولة',
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
            enabled: !_isUploading,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('settingsArchiveFileTypeField'),
            controller: _typeController,
            label: 'نوع الملف المكتشف',
            icon: Icons.description_outlined,
            accentColor: widget.accentColor,
            readOnly: true,
            enabled: false,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
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
              onPressed:
                  _isScanning || _isUploading ? null : _chooseFile,
            ),
          ),
          if (_isScanning && _file == null) ...[
            const SizedBox(height: AppSpacing.md),
            AppInfoBanner(
              key: const Key('settingsArchiveSelectionState'),
              message: 'جارٍ قراءة الملف المحدد بأمان...',
              icon: Icons.hourglass_top_rounded,
              foregroundColor: widget.accentColor,
              backgroundColor: Color.alphaBlend(
                widget.accentColor.withAlpha(18),
                AppColors.surface,
              ),
            ),
          ],
          if (_file != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSecurityState(),
          ],
          if (_uploadProgress != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildUploadState(),
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

  Widget _buildUploadState() {
    final progress = _uploadProgress!;
    final failed = progress.stage == ArchiveUploadStage.failed;
    return Column(
      key: const Key('settingsArchiveUploadProgressState'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'تقدم رفع ملف الأرشيف',
          value: '${(progress.fraction * 100).round()} بالمئة',
          child: LinearProgressIndicator(
            key: const Key('settingsArchiveUploadProgressIndicator'),
            value: progress.fraction,
            color: failed ? AppColors.danger : widget.accentColor,
            backgroundColor: AppColors.neutralSurface,
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppInfoBanner(
          key: const Key('settingsArchiveUploadProgressMessage'),
          message: progress.message,
          icon: failed
              ? Icons.cloud_off_outlined
              : Icons.cloud_upload_outlined,
          foregroundColor: failed ? AppColors.danger : widget.accentColor,
          backgroundColor: Color.alphaBlend(
            (failed ? AppColors.danger : widget.accentColor).withAlpha(18),
            AppColors.surface,
          ),
        ),
      ],
    );
  }
}

String _archiveFileTypeLabel(ArchiveFileType? type) => switch (type) {
      ArchiveFileType.pdf => 'PDF',
      ArchiveFileType.png => 'PNG',
      null => 'غير معروف',
    };

String _archiveRejectionMessage(ArchiveSecurityReport report) {
  if (report.issues.isNotEmpty) {
    return 'رُفض الملف: ${report.issues.map((issue) => issue.message).join(' — ')}';
  }
  if (report.scanStatus == MalwareScanStatus.failed) {
    return 'رُفض الملف لأن خدمة فحص البرمجيات الخبيثة غير متاحة';
  }
  return 'رُفض الملف لأن نتيجة الفحص الموثوقة غير مكتملة';
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
