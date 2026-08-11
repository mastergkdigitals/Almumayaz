part of '../settings_sections.dart';

String _backupFrequencyLabel(BackupFrequency frequency) => switch (frequency) {
      BackupFrequency.manual => 'يدوياً',
      BackupFrequency.daily => 'يومياً',
      BackupFrequency.weekly => 'أسبوعياً',
      BackupFrequency.monthly => 'شهرياً',
    };

BackupFrequency _backupFrequencyValue(String label) => switch (label) {
      'أسبوعياً' => BackupFrequency.weekly,
      'شهرياً' => BackupFrequency.monthly,
      'يدوياً' => BackupFrequency.manual,
      'عند إغلاق التطبيق' => BackupFrequency.manual,
      _ => BackupFrequency.daily,
    };

String _formatByteSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

String _shortChecksum(String checksum) {
  final prefixLength = checksum.length < 12 ? checksum.length : 12;
  return '${checksum.substring(0, prefixLength)}…';
}

String _formatAuditTimestamp(AuditTimestamp timestamp) {
  final local = timestamp.value.toLocal();
  final date = '${local.year.toString().padLeft(4, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.day.toString().padLeft(2, '0')}';
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'ص' : 'م';
  return '$date ${hour.toString().padLeft(2, '0')}:$minute $period';
}

String _serviceMessage(Object error) =>
    error is ServiceFailure ? error.message : 'تعذر إكمال العملية التجريبية';

String _settingsRepositoryMessage(Object error) {
  if (error is StateError) return error.message;
  if (error is FormatException) return 'أدخل القيم الرقمية بصيغة صحيحة';
  if (error is ArgumentError) return 'تحقق من القيم المدخلة';
  if (error is ServiceFailure) return error.message;
  return 'تعذر تحميل أو حفظ الإعدادات. حاول مرة أخرى.';
}

String _formatSettingsNumber(String value) {
  final normalized = value.trim().replaceAll(',', '');
  final parts = normalized.split('.');
  final integer = parts.first;
  final sign = integer.startsWith('-') ? '-' : '';
  final digits = sign.isEmpty ? integer : integer.substring(1);
  final buffer = StringBuffer(sign);
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  if (parts.length > 1 && parts[1].isNotEmpty) {
    buffer
      ..write('.')
      ..write(parts[1]);
  }
  return buffer.toString();
}

int _nextEntitySequence(
  Iterable<EntityId> ids, {
  required int fallback,
}) {
  var maximum = 0;
  for (final id in ids) {
    final sequence = int.tryParse(id.value.split('-').last);
    if (sequence != null && sequence > maximum) maximum = sequence;
  }
  return maximum == 0 ? fallback : maximum + 1;
}
