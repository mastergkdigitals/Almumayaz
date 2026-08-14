import 'package:flutter/material.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/config/app_configuration.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/services/service_failure.dart';
import '../../design_system/presentation/design_system_gallery_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configuration = AppConfigurationScope.of(context);
    final store = AppStoreScope.of(context);
    final showInternalDataTools =
        configuration.showDesignSystem && store.canManageInternalData;

    return AppScreenShell(
      key: const Key('aboutScreen'),
      title: 'حول البرنامج',
      onBack: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 112, showBackground: false),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'المميز للمحاسبة',
                    style: AppTypography.screenTitle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'نظام ERP عربي لإدارة أعمال الشركة ومخازنها ومستنداتها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppStatusBadge(
                        label: 'Windows',
                        tone: AppStatusTone.info,
                      ),
                      AppStatusBadge(
                        label: 'يعمل بدون إنترنت',
                        tone: AppStatusTone.success,
                      ),
                      AppStatusBadge(
                        label: 'دينار ودولار',
                        tone: AppStatusTone.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (configuration.showDesignSystem) ...[
                    AppRegularButton(
                      key: const Key('openDesignSystemGallery'),
                      label: 'دليل نظام التصميم',
                      icon: Icons.design_services_rounded,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const DesignSystemGalleryScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'أداة داخلية لمراجعة عناصر الواجهة أثناء التطوير',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (showInternalDataTools) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _InternalDataTools(
                        isBusy: store.isReplacingData,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InternalDataTools extends StatelessWidget {
  const _InternalDataTools({required this.isBusy});

  static const _restorePhrase = 'استعادة البيانات التجريبية';
  static const _deletePhrase = 'حذف جميع البيانات';

  final bool isBusy;

  Future<void> _openRestoreDialog(BuildContext context) {
    return _openConfirmation(
      context: context,
      title: 'استعادة البيانات التجريبية',
      message:
          'سيتم استبدال جميع البيانات الحالية بالبيانات التجريبية الأصلية، ثم إنهاء الجلسة.',
      phrase: _restorePhrase,
      confirmLabel: 'استعادة البيانات',
      progressMessage: 'جارٍ استعادة البيانات التجريبية...',
      variant: AppButtonVariant.warning,
      operation: (store) => store.restoreDemoData(),
    );
  }

  Future<void> _openDeleteDialog(BuildContext context) {
    return _openConfirmation(
      context: context,
      title: 'حذف جميع البيانات',
      message:
          'سيتم حذف جميع بيانات العمل نهائياً والإبقاء على هوية مدير النظام فقط، ثم إنهاء الجلسة.',
      phrase: _deletePhrase,
      confirmLabel: 'حذف جميع البيانات',
      progressMessage: 'جارٍ حذف جميع البيانات...',
      variant: AppButtonVariant.danger,
      operation: (store) => store.clearAllData(),
    );
  }

  Future<void> _openConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    required String phrase,
    required String confirmLabel,
    required String progressMessage,
    required AppButtonVariant variant,
    required Future<void> Function(AppStore store) operation,
  }) async {
    await AppTypedConfirmationDialog.show(
      context: context,
      title: title,
      message: message,
      confirmationPhrase: phrase,
      confirmLabel: confirmLabel,
      progressMessage: progressMessage,
      confirmVariant: variant,
      dialogKey: const Key('aboutDataConfirmationDialog'),
      fieldKey: const Key('aboutDataConfirmationField'),
      cancelButtonKey: const Key('aboutDataConfirmationCancelButton'),
      confirmButtonKey: const Key('aboutDataConfirmationConfirmButton'),
      progressKey: const Key('aboutDataOperationProgress'),
      onConfirm: () async {
        final configuration = AppConfigurationScope.of(context);
        final store = AppStoreScope.of(context, listen: false);
        if (!configuration.showDesignSystem ||
            !store.canManageInternalData) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.permissionDenied,
            code: 'internal_data_permission_changed',
            message:
                'لم تعد لديك صلاحية تنفيذ أدوات البيانات الداخلية.',
          );
        }
        await operation(store);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionPanel(
      key: const Key('aboutInternalDataTools'),
      title: 'أدوات البيانات الداخلية',
      icon: Icons.admin_panel_settings_rounded,
      accentColor: AppColors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'أدوات داخلية لمدير النظام فقط. كل عملية تستبدل بيانات التطبيق وتنهي الجلسة الحالية.',
            icon: Icons.info_outline_rounded,
            foregroundColor: AppColors.warningForeground,
            backgroundColor: AppColors.warningSurface,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                key: const Key('aboutRestoreDemoDataButton'),
                label: 'استعادة البيانات التجريبية',
                icon: Icons.restore_rounded,
                variant: AppButtonVariant.warning,
                minWidth: 246,
                onPressed: isBusy ? null : () => _openRestoreDialog(context),
              ),
              AppButton(
                key: const Key('aboutDeleteAllDataButton'),
                label: 'حذف جميع البيانات',
                icon: Icons.delete_forever_rounded,
                variant: AppButtonVariant.danger,
                minWidth: 246,
                onPressed: isBusy ? null : () => _openDeleteDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
