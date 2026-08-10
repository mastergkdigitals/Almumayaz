import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/audit_log/domain/audit_repository.dart';
import 'package:erp/features/backup_restore/data/demo_backup_services.dart';
import 'package:erp/features/backup_restore/domain/backup_models.dart';
import 'package:erp/features/backup_restore/domain/backup_services.dart';
import 'package:erp/features/settings/presentation/widgets/settings_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo backup configuration is isolated per Windows device', () async {
    final repository = DemoBackupConfigurationRepository();
    final first = await repository.load('windows-device-a');
    final second = await repository.load('windows-device-b');

    await repository.save(
      BackupConfiguration(
        deviceId: second.deviceId,
        localPath: r'E:\DeviceB\Backups',
        schedule: const BackupSchedule(
          isEnabled: true,
          frequency: BackupFrequency.weekly,
        ),
      ),
    );

    expect((await repository.load('windows-device-a')).localPath,
        first.localPath);
    expect(
      (await repository.load('windows-device-b')).localPath,
      r'E:\DeviceB\Backups',
    );
    expect(
      (await repository.load('windows-device-b')).schedule.frequency,
      BackupFrequency.weekly,
    );
  });

  test('Drive exposes service-backed folders and clean disconnection',
      () async {
    final drive = DemoGoogleDriveBackupService();
    expect(
      (await drive.connection()).status,
      CloudConnectionStatus.disconnected,
    );

    await drive.connect();
    final folders = await drive.listFolders();
    final selected = await drive.selectFolder(folders.last);
    expect(selected.selectedFolder?.id, folders.last.id);

    await drive.disconnect();
    final disconnected = await drive.connection();
    expect(disconnected.status, CloudConnectionStatus.disconnected);
    expect(disconnected.selectedFolder, isNull);
  });

  testWidgets(
      'backup UI uses injected directory/source selection and Drive folders',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selections = _RecordingBackupFileSelectionService();
    final drive = DemoGoogleDriveBackupService();
    final configurations = DemoBackupConfigurationRepository();
    final audit = _RecordingAuditWriter();

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: BackupDataSettingsSection(
              accentColor: AppModulePalettes.reports.middle,
              deviceId: 'windows-phase5-test',
              configurationRepository: configurations,
              googleDriveService: drive,
              backupService: DemoBackupService(
                googleDriveService: drive,
              ),
              fileSelectionService: selections,
              auditWriter: audit,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('settingsBrowseLocalBackupPath')),
    );
    await tester.pumpAndSettle();
    expect(selections.directoryCalls, 1);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('settingsLocalBackupPathField')),
          )
          .controller
          ?.text,
      r'E:\Selected\Backups',
    );

    await tester.tap(
      find.byKey(const Key('settingsToggleDriveConnectionButton')),
    );
    await tester.pumpAndSettle();
    expect(find.text('الحساب مرتبط وجاهز للنسخ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settingsDriveFolderField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly Backups').last);
    await tester.pumpAndSettle();
    expect(
      (await drive.connection()).selectedFolder?.name,
      'Monthly Backups',
    );

    await tester.tap(
      find.byKey(const Key('settingsToggleDriveConnectionButton')),
    );
    await tester.pumpAndSettle();
    expect(
      (await drive.connection()).status,
      CloudConnectionStatus.disconnected,
    );

    final runBackupButton =
        find.byKey(const Key('settingsRunBackupButton'));
    await tester.ensureVisible(runBackupButton);
    await tester.pump();
    await tester.tap(runBackupButton);
    await tester.pumpAndSettle();
    expect(
      audit.events.where((event) => event.action == AuditAction.backup),
      hasLength(1),
    );

    final restoreButton =
        find.byKey(const Key('settingsRestoreBackupButton'));
    await tester.ensureVisible(restoreButton);
    await tester.pump();
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();
    expect(selections.restoreCalls, 1);
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('اكتملت الاستعادة التجريبية'),
      findsWidgets,
    );
    expect(
      audit.events.where((event) => event.action == AuditAction.restore),
      hasLength(1),
    );
    expect(
      audit.events.where(
        (event) =>
            event.action == AuditAction.update &&
            event.details['workflow'] == 'googleDriveBackup',
      ),
      hasLength(2),
    );
  });
}

class _RecordingAuditWriter implements AuditEventWriter {
  final events = <AuditEvent>[];

  @override
  Future<AuditRecord> write(AuditEvent event) async {
    events.add(event);
    final sequence = events.length;
    return AuditRecord(
      id: EntityId.demo('audit', sequence),
      occurredAt: AuditTimestamp(DateTime.utc(2026, 8, 10, 12, sequence)),
      actorUserId: EntityId.demo('user', 1),
      actorUsername: 'admin',
      action: event.action,
      outcome: event.outcome,
      summary: event.summary,
      details: event.details,
      metadata: AuditMetadata(
        deviceId: 'test-device',
        requestId: 'phase5-$sequence',
        before: event.before,
        after: event.after,
      ),
      entityType: event.entityType,
      entityId: event.entityId,
    );
  }
}

class _RecordingBackupFileSelectionService
    implements BackupFileSelectionService {
  var directoryCalls = 0;
  var restoreCalls = 0;

  @override
  Future<String?> selectBackupDirectory({String? initialDirectory}) async {
    directoryCalls++;
    return r'E:\Selected\Backups';
  }

  @override
  Future<ExternalBackupSource?> selectRestoreSource({
    String? initialDirectory,
  }) async {
    restoreCalls++;
    return ExternalBackupSource(
      localPath: r'E:\Selected\restore-source.backup',
    );
  }
}
