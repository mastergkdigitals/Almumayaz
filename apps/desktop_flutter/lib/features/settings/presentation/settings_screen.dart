import 'package:flutter/material.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/app_state/app_services.dart';
import '../../../core/design/app_design_system.dart';
import '../../permissions/domain/permission_models.dart';
import 'widgets/settings_sections.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsSection? _selectedSection;

  void _openSection(_SettingsSection section) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedSection = section);
  }

  void _handleBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectedSection != null) {
      setState(() => _selectedSection = null);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final canViewSettings = store.session == null ||
        store.allows('settings', PermissionAction.view);
    final canManageSettings = store.allows(
      'settings',
      PermissionAction.manage,
    );
    final selectedSection = _selectedSection;
    final accentColor =
        selectedSection?.palette.middle ?? AppModuleColors.settings;
    final tint = Color.alphaBlend(
      accentColor.withAlpha(12),
      AppColors.surface,
    );

    return PopScope(
      canPop: selectedSection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: AppScreenShell(
        key: const Key('settingsScreen'),
        title: selectedSection?.title ?? 'الإعدادات',
        backgroundColor: tint,
        onBack: _handleBack,
        body: ColoredBox(
          key: const Key('settingsTintBackground'),
          color: tint,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: !canViewSettings
                  ? const _SettingsViewPermissionNotice()
                  : selectedSection == null
                  ? _SettingsHub(
                      canManageSettings: canManageSettings,
                      onOpenSection: _openSection,
                    )
                  : KeyedSubtree(
                      key: Key('settingsSection_${selectedSection.id}'),
                      child: _buildSection(selectedSection),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(_SettingsSection section) {
    final store = AppStoreScope.of(context, listen: false);
    final canViewSettings = store.session == null ||
        store.allows('settings', PermissionAction.view);
    if (!canViewSettings) return const _SettingsViewPermissionNotice();
    final canManageSettings = store.allows(
      'settings',
      PermissionAction.manage,
    );
    if (!canManageSettings && section != _SettingsSection.usersSecurity) {
      return const _SettingsPermissionNotice();
    }
    final services = store.services;
    return switch (section) {
      _SettingsSection.businessPolicies =>
        BusinessPoliciesSettingsSection(
          accentColor: section.palette.middle,
        ),
      _SettingsSection.defaultSettings =>
        OperationalDefaultsSettingsSection(
          accentColor: section.palette.middle,
        ),
      _SettingsSection.masterData => MasterDataSettingsSection(
          accentColor: section.palette.middle,
        ),
      _SettingsSection.backup => BackupDataSettingsSection(
          accentColor: section.palette.middle,
          configurationRepository: services.backupConfiguration,
          backupService: services.backups,
          googleDriveService: services.googleDriveBackups,
          fileSelectionService: services.backupFileSelection,
          auditWriter: services.auditWriter,
          deviceId: almumayazWindowsDeviceId,
        ),
      _SettingsSection.usersSecurity =>
        UsersSecuritySettingsSection(
          accentColor: section.palette.middle,
          userRepository: services.users,
          roleRepository: services.roles,
          authenticationService: services.authentication,
          sessionPolicyRepository: services.sessionPolicies,
          auditRepository: services.audit,
          administrationService: services.administration,
        ),
      _SettingsSection.archive =>
        ElectronicArchiveSettingsSection(
          accentColor: section.palette.middle,
          securityService: services.archiveSecurity,
          repository: services.archive,
          validationPolicy: services.archiveValidationPolicy,
          fileSelectionService: services.archiveFileSelection,
          auditWriter: services.auditWriter,
        ),
    };
  }
}

class _SettingsHub extends StatelessWidget {
  const _SettingsHub({
    required this.canManageSettings,
    required this.onOpenSection,
  });

  final bool canManageSettings;
  final ValueChanged<_SettingsSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('settingsHub'),
      children: [
        Expanded(
          child: _SettingsHubRow(
            sections: const [
              _SettingsSection.businessPolicies,
              _SettingsSection.defaultSettings,
            ],
            canManageSettings: canManageSettings,
            onOpenSection: onOpenSection,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _SettingsHubRow(
            sections: const [
              _SettingsSection.masterData,
              _SettingsSection.backup,
            ],
            canManageSettings: canManageSettings,
            onOpenSection: onOpenSection,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _SettingsHubRow(
            sections: const [
              _SettingsSection.usersSecurity,
              _SettingsSection.archive,
            ],
            canManageSettings: canManageSettings,
            onOpenSection: onOpenSection,
          ),
        ),
      ],
    );
  }
}

class _SettingsHubRow extends StatelessWidget {
  const _SettingsHubRow({
    required this.sections,
    required this.canManageSettings,
    required this.onOpenSection,
  });

  final List<_SettingsSection> sections;
  final bool canManageSettings;
  final ValueChanged<_SettingsSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppModuleCard(
              key: Key('settingsSectionCard_${sections[index].id}'),
              title: sections[index].title,
              icon: sections[index].icon,
              colors: sections[index].palette.gradient,
              shadowColor: sections[index].palette.shadow,
              onTap: canManageSettings ||
                      sections[index] == _SettingsSection.usersSecurity
                  ? () => onOpenSection(sections[index])
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _SettingsPermissionNotice extends StatelessWidget {
  const _SettingsPermissionNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620),
        child: AppInfoBanner(
          key: Key('settingsManagePermissionRequired'),
          message: 'تتطلب هذه الصفحة صلاحية إدارة الإعدادات',
          icon: Icons.lock_outline_rounded,
          foregroundColor: AppColors.warning,
          backgroundColor: AppColors.warningSurface,
        ),
      ),
    );
  }
}

class _SettingsViewPermissionNotice extends StatelessWidget {
  const _SettingsViewPermissionNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620),
        child: AppInfoBanner(
          key: Key('settingsViewPermissionRequired'),
          message: 'ليست لديك صلاحية عرض الإعدادات',
          icon: Icons.lock_outline_rounded,
          foregroundColor: AppColors.danger,
          backgroundColor: AppColors.dangerSurface,
        ),
      ),
    );
  }
}

enum _SettingsSection {
  businessPolicies(
    id: 'businessPolicies',
    title: 'سياسات العمل',
    icon: Icons.policy_rounded,
    palette: AppModulePalettes.settings,
  ),
  defaultSettings(
    id: 'defaultSettings',
    title: 'الإعدادات الافتراضية',
    icon: Icons.tune_rounded,
    palette: AppModulePalettes.settingsDefaults,
  ),
  masterData(
    id: 'masterData',
    title: 'إدارة البيانات الأساسية',
    icon: Icons.account_tree_rounded,
    palette: AppModulePalettes.parties,
  ),
  backup(
    id: 'backup',
    title: 'النسخ الاحتياطي والبيانات',
    icon: Icons.backup_rounded,
    palette: AppModulePalettes.reports,
  ),
  usersSecurity(
    id: 'usersSecurity',
    title: 'المستخدمون والأمان',
    icon: Icons.admin_panel_settings_rounded,
    palette: AppModulePalettes.settingsSecurity,
  ),
  archive(
    id: 'archive',
    title: 'الأرشيف الإلكتروني',
    icon: Icons.inventory_2_rounded,
    palette: AppModulePalettes.sales,
  );

  const _SettingsSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.palette,
  });

  final String id;
  final String title;
  final IconData icon;
  final AppModulePalette palette;
}
