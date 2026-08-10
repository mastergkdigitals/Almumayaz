import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../../../core/services/service_failure.dart';
import '../domain/backup_models.dart';
import '../domain/backup_services.dart';

class DesktopBackupFileSelectionService
    implements BackupFileSelectionService {
  const DesktopBackupFileSelectionService();

  @override
  Future<String?> selectBackupDirectory({String? initialDirectory}) async {
    _requireWindows();
    try {
      return await getDirectoryPath(
        initialDirectory: initialDirectory,
        confirmButtonText: 'اختيار المجلد',
      );
    } on Object catch (error) {
      throw ServiceFailure(
        kind: ServiceFailureKind.unavailable,
        code: 'backup_directory_picker_failed',
        message: 'تعذر فتح نافذة اختيار مجلد النسخ',
        cause: error,
      );
    }
  }

  @override
  Future<ExternalBackupSource?> selectRestoreSource({
    String? initialDirectory,
  }) async {
    _requireWindows();
    try {
      final selected = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'نسخ Almumayaz الاحتياطية',
            extensions: ['backup'],
          ),
        ],
        initialDirectory: initialDirectory,
        confirmButtonText: 'اختيار النسخة',
      );
      if (selected == null) return null;
      return ExternalBackupSource(localPath: selected.path);
    } on Object catch (error) {
      throw ServiceFailure(
        kind: ServiceFailureKind.unavailable,
        code: 'backup_restore_picker_failed',
        message: 'تعذر فتح نافذة اختيار النسخة الاحتياطية',
        cause: error,
      );
    }
  }

  void _requireWindows() {
    if (Platform.isWindows) return;
    throw const ServiceFailure(
      kind: ServiceFailureKind.unavailable,
      code: 'backup_picker_windows_only',
      message: 'اختيار ملفات النسخ متاح في إصدار Windows فقط',
    );
  }
}
