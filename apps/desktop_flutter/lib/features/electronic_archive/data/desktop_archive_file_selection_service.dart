import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../../../core/services/service_failure.dart';
import '../domain/archive_models.dart';
import '../domain/archive_services.dart';

/// Windows file picker and bounded byte reader used by the archive preflight.
///
/// Only files within the configured limit are read completely. Oversized
/// files expose a small signature prefix so they can be rejected without
/// allocating their full content in memory.
class DesktopArchiveFileSelectionService
    implements ArchiveFileSelectionService {
  const DesktopArchiveFileSelectionService();

  @override
  Future<ArchiveFileCandidate?> selectFile({
    required ArchiveValidationPolicy policy,
  }) async {
    if (!Platform.isWindows) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.unavailable,
        code: 'archive_picker_windows_only',
        message: 'اختيار ملفات الأرشيف متاح في إصدار Windows فقط',
      );
    }
    try {
      final selected = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'ملفات PDF وPNG',
            extensions: ['pdf', 'png'],
          ),
        ],
        confirmButtonText: 'اختيار',
      );
      if (selected == null) return null;
      final file = File(selected.path);
      final byteSize = await file.length();
      final isComplete = byteSize <= policy.maximumByteSize;
      final bytes = isComplete
          ? await file.readAsBytes()
          : await _readPrefix(file, 16);
      return ArchiveFileCandidate(
        localPath: selected.path,
        fileName: selected.name,
        byteSize: byteSize,
        declaredMimeType: selected.mimeType,
        contentBytes: bytes,
        contentIsComplete: isComplete,
      );
    } on Object catch (error) {
      throw ServiceFailure(
        kind: ServiceFailureKind.unavailable,
        code: 'archive_file_selection_failed',
        message: 'تعذر اختيار الملف أو قراءة محتواه',
        cause: error,
      );
    }
  }
}

Future<List<int>> _readPrefix(File file, int maximumLength) async {
  final handle = await file.open();
  try {
    return await handle.read(maximumLength);
  } finally {
    await handle.close();
  }
}
