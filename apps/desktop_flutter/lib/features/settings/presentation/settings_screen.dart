import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import 'widgets/settings_sections.dart';

const _oldDefaultsSettingsPalette = AppModulePalette(
  dark: Color(0xFF312E81),
  middle: Color(0xFF4F46E5),
  light: Color(0xFFA5B4FC),
  shadow: Color(0xFF4F46E5),
);

const _oldActivityLogPalette = AppModulePalette(
  dark: Color(0xFF7F1D1D),
  middle: Color(0xFFDC2626),
  light: Color(0xFFFCA5A5),
  shadow: Color(0xFFB91C1C),
);

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
              child: selectedSection == null
                  ? _SettingsHub(onOpenSection: _openSection)
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
        ),
      _SettingsSection.usersSecurity =>
        UsersSecuritySettingsSection(
          accentColor: section.palette.middle,
        ),
      _SettingsSection.archive =>
        ElectronicArchiveSettingsSection(
          accentColor: section.palette.middle,
        ),
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
            child: AppModuleCard(
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
    palette: _oldDefaultsSettingsPalette,
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
    palette: _oldActivityLogPalette,
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
