import '../../features/audit_log/data/demo_audit_repository.dart';
import '../../features/audit_log/domain/audit_repository.dart';
import '../../features/authentication/data/demo_authentication_service.dart';
import '../../features/authentication/domain/authentication_service.dart';
import '../../features/backup_restore/data/demo_backup_services.dart';
import '../../features/backup_restore/domain/backup_services.dart';
import '../../features/electronic_archive/data/demo_archive_services.dart';
import '../../features/electronic_archive/domain/archive_models.dart';
import '../../features/electronic_archive/domain/archive_services.dart';
import '../../features/permissions/data/demo_role_repository.dart';
import '../../features/permissions/domain/role_repository.dart';
import '../../features/users/data/demo_user_repository.dart';
import '../../features/users/domain/user_repository.dart';

/// Long-lived application services that are not ordinary business-data
/// repositories.
///
/// The Flutter-only adapters are deliberately deterministic and in-memory.
/// Keeping them in the app composition root makes workflow state survive
/// closing and reopening a screen, while the same interfaces can later be
/// backed by the API, Windows file services, OAuth and malware scanning.
class AppServices {
  const AppServices({
    required this.authentication,
    required this.sessionPolicies,
    required this.backupConfiguration,
    required this.backups,
    required this.googleDriveBackups,
    required this.archiveSecurity,
    required this.archive,
    required this.archiveValidationPolicy,
    required this.users,
    required this.roles,
    required this.audit,
  });

  factory AppServices.demo() {
    final googleDriveBackups = DemoGoogleDriveBackupService();
    return AppServices(
      authentication: DemoAuthenticationService(startsAuthenticated: false),
      sessionPolicies: DemoSessionPolicyRepository(),
      backupConfiguration: DemoBackupConfigurationRepository(),
      backups: DemoBackupService(
        googleDriveService: googleDriveBackups,
      ),
      googleDriveBackups: googleDriveBackups,
      archiveSecurity: DemoArchiveSecurityService(),
      archive: DemoArchiveRepository(),
      archiveValidationPolicy: ArchiveValidationPolicy(
        maximumByteSize: 10 * 1024 * 1024,
      ),
      users: DemoUserRepository(),
      roles: DemoRoleRepository(),
      audit: DemoAuditRepository(),
    );
  }

  final AuthenticationService authentication;
  final SessionPolicyRepository sessionPolicies;
  final BackupConfigurationRepository backupConfiguration;
  final BackupService backups;
  final GoogleDriveBackupService googleDriveBackups;
  final ArchiveSecurityService archiveSecurity;
  final ArchiveRepository archive;
  final ArchiveValidationPolicy archiveValidationPolicy;
  final UserRepository users;
  final RoleRepository roles;
  final AuditRepository audit;
}
