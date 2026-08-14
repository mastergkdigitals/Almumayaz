import 'dart:async';

import '../../features/audit_log/data/demo_audit_repository.dart';
import '../../features/audit_log/domain/audit_models.dart';
import '../../features/audit_log/domain/audit_repository.dart';
import '../../features/authentication/data/demo_authentication_service.dart';
import '../../features/authentication/data/demo_identity_state.dart';
import '../../features/authentication/domain/authentication_service.dart';
import '../../features/authentication/domain/session_models.dart';
import '../../features/backup_restore/application/audited_backup_services.dart';
import '../../features/backup_restore/data/demo_backup_services.dart';
import '../../features/backup_restore/data/desktop_backup_file_selection_service.dart';
import '../../features/backup_restore/domain/backup_models.dart';
import '../../features/backup_restore/domain/backup_services.dart';
import '../../features/electronic_archive/application/audited_archive_services.dart';
import '../../features/electronic_archive/data/demo_archive_services.dart';
import '../../features/electronic_archive/data/desktop_archive_file_selection_service.dart';
import '../../features/electronic_archive/domain/archive_models.dart';
import '../../features/electronic_archive/domain/archive_services.dart';
import '../../features/permissions/domain/role_repository.dart';
import '../../features/reports/application/audited_report_output_service.dart';
import '../../features/reports/application/document_report_output_service.dart';
import '../../features/reports/application/report_output_service.dart';
import '../../features/settings/domain/settings_models.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/users/domain/user_repository.dart';
import '../printing/audited_document_output_service.dart';
import '../printing/desktop_document_output_service.dart';
import '../printing/document_output_service.dart';
import '../services/app_operation_gate.dart';
import 'app_data_profile.dart';

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
    this.operationGate,
    this.documentOutput = const DemoDocumentOutputService(),
    this.reportOutput = const DemoReportOutputService(),
  });

  factory AppServices.demo({
    AppDataProfile profile = AppDataProfile.originalDemo,
    DemoIdentityServiceBundle? identityBundle,
    AppOperationGate? operationGate,
  }) {
    final isCleared = profile == AppDataProfile.cleared;
    final identity = identityBundle ??
        DemoIdentityServiceBundle(
          startsAuthenticated: false,
          state: isCleared ? DemoIdentityState.bootstrap() : null,
        );
    final auditWriter = identity.auditWriter;
    final sharedOperationGate = operationGate ?? AppOperationGate();
    final rawGoogleDriveBackups = DemoGoogleDriveBackupService();
    final googleDriveBackups = AuditedGoogleDriveBackupService(
      delegate: rawGoogleDriveBackups,
      auditWriter: auditWriter,
      operationGate: sharedOperationGate,
    );
    final documentOutput = AuditedDocumentOutputService(
      delegate: const DemoDocumentOutputService(),
      auditWriter: auditWriter,
      operationGate: sharedOperationGate,
    );
    return AppServices(
      authentication: identity.authentication,
      sessionPolicies: identity.sessionPolicies,
      administration: identity.administration,
      auditWriter: auditWriter,
      backupConfiguration: AuditedBackupConfigurationRepository(
        delegate: DemoBackupConfigurationRepository(),
        auditWriter: auditWriter,
        operationGate: sharedOperationGate,
      ),
      backups: AuditedBackupService(
        delegate: DemoBackupService(
          googleDriveService: googleDriveBackups,
          initialHistory: isCleared ? const <BackupRecord>[] : null,
        ),
        auditWriter: auditWriter,
        operationGate: sharedOperationGate,
      ),
      backupFileSelection: DemoBackupFileSelectionService(),
      googleDriveBackups: googleDriveBackups,
      archiveSecurity: AuditedArchiveSecurityService(
        delegate: DemoArchiveSecurityService(),
        auditWriter: auditWriter,
        operationGate: sharedOperationGate,
      ),
      archive: AuditedArchiveRepository(
        delegate: DemoArchiveRepository(
          initialDocuments: isCleared ? const <ArchiveDocument>[] : null,
          currentUserId: () {
            final session = identity.state.currentSession;
            if (session == null || session.state != SessionState.active) {
              return null;
            }
            return session.userId;
          },
        ),
        auditWriter: auditWriter,
        operationGate: sharedOperationGate,
      ),
      archiveFileSelection: DemoArchiveFileSelectionService(),
      archiveValidationPolicy: ArchiveValidationPolicy(
        maximumByteSize: 10 * 1024 * 1024,
      ),
      users: identity.users,
      roles: identity.roles,
      audit: identity.audit,
      operationGate: sharedOperationGate,
      documentOutput: documentOutput,
      reportOutput: AuditedReportOutputService(
        delegate: const DemoReportOutputService(),
        auditWriter: auditWriter,
        operationGate: sharedOperationGate,
      ),
    );
  }

  factory AppServices.desktop({
    required DeviceSettingsRepository deviceSettings,
    AppDataProfile profile = AppDataProfile.originalDemo,
    DemoIdentityServiceBundle? identityBundle,
    AppOperationGate? operationGate,
  }) {
    final isCleared = profile == AppDataProfile.cleared;
    final identity = identityBundle ??
        DemoIdentityServiceBundle(
          startsAuthenticated: false,
          state: isCleared ? DemoIdentityState.bootstrap() : null,
        );
    final auditWriter = identity.auditWriter;
    final sharedOperationGate = operationGate ?? AppOperationGate();
    final rawGoogleDriveBackups = DemoGoogleDriveBackupService();
    final googleDriveBackups = AuditedGoogleDriveBackupService(
      delegate: rawGoogleDriveBackups,
      auditWriter: auditWriter,
      operationGate: sharedOperationGate,
    );
    final documentOutput = AuditedDocumentOutputService(
      delegate: DesktopDocumentOutputService(
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
      ),
      auditWriter: auditWriter,
      operationGate: sharedOperationGate,
    );
    final reportOutput = DocumentBackedReportOutputService(
      printService: documentOutput,
      exportService: documentOutput,
    );
    return AppServices(
      authentication: identity.authentication,
      sessionPolicies: identity.sessionPolicies,
      administration: identity.administration,
      auditWriter: auditWriter,
      backupConfiguration: AuditedBackupConfigurationRepository(
        delegate: DemoBackupConfigurationRepository(),
        auditWriter: auditWriter,
        operationGate: sharedOperationGate,
      ),
      backups: AuditedBackupService(
        delegate: DemoBackupService(
          googleDriveService: googleDriveBackups,
          initialHistory: isCleared ? const <BackupRecord>[] : null,
        ),
        auditWriter: auditWriter,
        operationGate: sharedOperationGate,
      ),
      backupFileSelection: const DesktopBackupFileSelectionService(),
      googleDriveBackups: googleDriveBackups,
      archiveSecurity: AuditedArchiveSecurityService(
        delegate: DemoArchiveSecurityService(),
        auditWriter: auditWriter,
        operationGate: sharedOperationGate,
      ),
      archive: AuditedArchiveRepository(
        delegate: DemoArchiveRepository(
          initialDocuments: isCleared ? const <ArchiveDocument>[] : null,
          currentUserId: () {
            final session = identity.state.currentSession;
            if (session == null || session.state != SessionState.active) {
              return null;
            }
            return session.userId;
          },
        ),
        auditWriter: auditWriter,
        operationGate: sharedOperationGate,
      ),
      archiveFileSelection: const DesktopArchiveFileSelectionService(),
      archiveValidationPolicy: ArchiveValidationPolicy(
        maximumByteSize: 10 * 1024 * 1024,
      ),
      users: identity.users,
      roles: identity.roles,
      audit: identity.audit,
      operationGate: sharedOperationGate,
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
  final AppOperationGate? operationGate;
  final DocumentOutputService documentOutput;
  final ReportOutputService reportOutput;

  /// Stops accepting new demo transactions, drains accepted work, and grants
  /// the caller one final turn in which to replace the live graph.
  ///
  /// A failed final turn reopens the old graph's runner. A successful turn
  /// retires it permanently so stale repository references cannot mutate it.
  Future<T> retireTransactionsForDataReplacement<T>(
    FutureOr<T> Function() finalTurn,
  ) {
    return _demoIdentityStateForDataReplacement()
        .transactionRunner
        .retireAfterDrain(finalTurn);
  }

  AppOperationRetirement beginOperationRetirementForDataReplacement() {
    final gate = operationGate;
    if (gate == null) {
      throw StateError(
        'Internal data replacement requires a shared application operation gate.',
      );
    }
    return gate.beginRetirement();
  }

  List<AuditRecord> auditHistoryForDataReplacement() {
    return _demoIdentityStateForDataReplacement().auditHistorySnapshot();
  }

  void installAuditHistoryForDataReplacement(
    Iterable<AuditRecord> records,
  ) {
    _demoIdentityStateForDataReplacement()
        .replaceAuditHistoryForDataReplacement(records);
  }

  /// Revokes the discarded demo identity graph during the no-fail swap.
  /// API-backed compositions revoke their authoritative session server-side;
  /// clearing the store session remains the client-side fail-closed boundary.
  bool revokeSessionForDataReplacement(AppSession expectedSession) {
    final adapter = authentication;
    if (adapter is DemoAuthenticationService) {
      return adapter.revokeForDataReplacement(expectedSession);
    }
    return false;
  }

  DemoIdentityState _demoIdentityStateForDataReplacement() {
    final authenticationAdapter = authentication;
    final auditAdapter = audit;
    if (authenticationAdapter is! DemoAuthenticationService ||
        auditAdapter is! DemoAuditRepository ||
        !identical(
          authenticationAdapter.identityState,
          auditAdapter.identityState,
        )) {
      throw StateError(
        'Internal data replacement requires one shared demo identity state.',
      );
    }
    return authenticationAdapter.identityState;
  }
}
