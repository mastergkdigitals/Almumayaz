import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import '../../dashboard/presentation/dashboard_card.dart';
import 'widgets/settings_sections.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsSection? _selectedSection;

  void _openSection(_SettingsSection section) {
    setState(() => _selectedSection = section);
  }

  void _handleBack() {
    if (_selectedSection != null) {
      setState(() => _selectedSection = null);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tint = Color.alphaBlend(
      AppModuleColors.settings.withAlpha(12),
      AppColors.surface,
    );
    final selectedSection = _selectedSection;

    return AppScreenShell(
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
            child: selectedSection == null
                ? _SettingsHub(onOpenSection: _openSection)
                : KeyedSubtree(
                    key: Key('settingsSection_${selectedSection.id}'),
                    child: _buildSection(selectedSection),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(_SettingsSection section) {
    return switch (section) {
      _SettingsSection.businessPolicies =>
        const BusinessPoliciesSettingsSection(),
      _SettingsSection.defaultSettings =>
        const OperationalDefaultsSettingsSection(),
      _SettingsSection.printing => const PrintingSettingsSection(),
      _SettingsSection.masterData => const MasterDataSettingsSection(),
      _SettingsSection.backup => const BackupDataSettingsSection(),
      _SettingsSection.usersSecurity =>
        const UsersSecuritySettingsSection(),
      _SettingsSection.archive =>
        const ElectronicArchiveSettingsSection(),
    };
  }
}

class _SettingsHub extends StatelessWidget {
  const _SettingsHub({required this.onOpenSection});

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
              _SettingsSection.printing,
            ],
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
    required this.onOpenSection,
  });

  final List<_SettingsSection> sections;
  final ValueChanged<_SettingsSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DashboardCard(
              key: Key('settingsSectionCard_${sections[index].id}'),
              title: sections[index].title,
              icon: sections[index].icon,
              colors: sections[index].palette.gradient,
              shadowColor: sections[index].palette.shadow,
              onTap: () => onOpenSection(sections[index]),
            ),
          ),
        ],
      ],
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
    palette: AppModulePalettes.cashbox,
  ),
  printing(
    id: 'printing',
    title: 'الطباعة',
    icon: Icons.print_rounded,
    palette: AppModulePalettes.sales,
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
    palette: AppModulePalettes.purchases,
  ),
  usersSecurity(
    id: 'usersSecurity',
    title: 'المستخدمون والأمان',
    icon: Icons.admin_panel_settings_rounded,
    palette: AppModulePalettes.about,
  ),
  archive(
    id: 'archive',
    title: 'الأرشيف الإلكتروني',
    icon: Icons.inventory_2_rounded,
    palette: AppModulePalettes.reports,
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
