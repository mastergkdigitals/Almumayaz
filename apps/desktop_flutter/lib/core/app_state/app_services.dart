import '../../features/audit_log/domain/audit_repository.dart';
import '../../features/authentication/data/demo_authentication_service.dart';
import '../../features/authentication/domain/authentication_service.dart';
import '../../features/authentication/domain/session_models.dart';
import '../../features/backup_restore/data/demo_backup_services.dart';
import '../../features/backup_restore/data/desktop_backup_file_selection_service.dart';
import '../../features/backup_restore/domain/backup_services.dart';
import '../../features/electronic_archive/data/demo_archive_services.dart';
import '../../features/electronic_archive/data/desktop_archive_file_selection_service.dart';
import '../../features/electronic_archive/domain/archive_models.dart';
import '../../features/electronic_archive/domain/archive_services.dart';
import '../../features/permissions/domain/role_repository.dart';
import '../../features/reports/application/document_report_output_service.dart';
import '../../features/reports/application/report_output_service.dart';
import '../../features/settings/domain/settings_models.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/users/domain/user_repository.dart';
import '../printing/desktop_document_output_service.dart';
import '../printing/document_output_service.dart';

const almumayazWindowsDeviceId = 'demo-windows-device';

/// Long-lived application services that are not ordinary business-data
/// repositories.
///
/// Demo adapters are deterministic and in-memory, while the desktop
/// composition replaces document output with native Windows adapters.
/// Keeping both behind the same contracts lets tests stay deterministic and
/// later API integrations replace services without changing widgets.
class AppServices {
  const AppServices({
    required this.authentication,
    required this.sessionPolicies,
    required this.administration,
    required this.auditWriter,
    required this.backupConfiguration,
    required this.backups,
    required this.backupFileSelection,
    required this.googleDriveBackups,
    required this.archiveSecurity,
    required this.archive,
    required this.archiveFileSelection,
    required this.archiveValidationPolicy,
    required this.users,
    required this.roles,
    required this.audit,
    this.documentOutput = const DemoDocumentOutputService(),
    this.reportOutput = const DemoReportOutputService(),
  });

  factory AppServices.demo() {
    final identity = DemoIdentityServiceBundle(startsAuthenticated: false);
    final googleDriveBackups = DemoGoogleDriveBackupService();
    return AppServices(
      authentication: identity.authentication,
      sessionPolicies: identity.sessionPolicies,
      administration: identity.administration,
      auditWriter: identity.auditWriter,
      backupConfiguration: DemoBackupConfigurationRepository(),
      backups: DemoBackupService(
        googleDriveService: googleDriveBackups,
      ),
      backupFileSelection: DemoBackupFileSelectionService(),
      googleDriveBackups: googleDriveBackups,
      archiveSecurity: DemoArchiveSecurityService(),
      archive: DemoArchiveRepository(
        currentUserId: () {
          final session = identity.state.currentSession;
          if (session == null || session.state != SessionState.active) {
            return null;
          }
          return session.userId;
        },
      ),
      archiveFileSelection: DemoArchiveFileSelectionService(),
      archiveValidationPolicy: ArchiveValidationPolicy(
        maximumByteSize: 10 * 1024 * 1024,
      ),
      users: identity.users,
      roles: identity.roles,
      audit: identity.audit,
    );
  }

  factory AppServices.desktop({
    required DeviceSettingsRepository deviceSettings,
  }) {
    final identity = DemoIdentityServiceBundle(startsAuthenticated: false);
    final googleDriveBackups = DemoGoogleDriveBackupService();
    final documentOutput = DesktopDocumentOutputService(
      settingsLoader: () async {
        final settings = await deviceSettings.loadDeviceSettings(
          almumayazWindowsDeviceId,
        );
        return DocumentOutputSettings(
          defaultPrinterName: settings.defaultPrinterName,
          paperSize: settings.paperSize == PrintPaperSize.a5
              ? DocumentPaperSize.a5
              : DocumentPaperSize.a4,
          copies: settings.printCopies,
          previewEnabled: settings.printPreviewEnabled,
        );
      },
    );
    final reportOutput = DocumentBackedReportOutputService(
      printService: documentOutput,
      exportService: documentOutput,
    );
    return AppServices(
      authentication: identity.authentication,
      sessionPolicies: identity.sessionPolicies,
      administration: identity.administration,
      auditWriter: identity.auditWriter,
      backupConfiguration: DemoBackupConfigurationRepository(),
      backups: DemoBackupService(
        googleDriveService: googleDriveBackups,
      ),
      backupFileSelection: const DesktopBackupFileSelectionService(),
      googleDriveBackups: googleDriveBackups,
      archiveSecurity: DemoArchiveSecurityService(),
      archive: DemoArchiveRepository(
        currentUserId: () {
          final session = identity.state.currentSession;
          if (session == null || session.state != SessionState.active) {
            return null;
          }
          return session.userId;
        },
      ),
      archiveFileSelection: const DesktopArchiveFileSelectionService(),
      archiveValidationPolicy: ArchiveValidationPolicy(
        maximumByteSize: 10 * 1024 * 1024,
      ),
      users: identity.users,
      roles: identity.roles,
      audit: identity.audit,
      documentOutput: documentOutput,
      reportOutput: reportOutput,
    );
  }

  final AuthenticationService authentication;
  final SessionPolicyRepository sessionPolicies;
  final SecurityAdministrationService administration;
  final AuditEventWriter auditWriter;
  final BackupConfigurationRepository backupConfiguration;
  final BackupService backups;
  final BackupFileSelectionService backupFileSelection;
  final GoogleDriveBackupService googleDriveBackups;
  final ArchiveSecurityService archiveSecurity;
  final ArchiveRepository archive;
  final ArchiveFileSelectionService archiveFileSelection;
  final ArchiveValidationPolicy archiveValidationPolicy;
  final UserRepository users;
  final RoleRepository roles;
  final AuditRepository audit;
  final DocumentOutputService documentOutput;
  final ReportOutputService reportOutput;
}
