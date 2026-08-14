import 'package:flutter/material.dart';

import '../../services/service_failure.dart';
import '../app_tokens.dart';
import 'app_button.dart';
import 'app_feedback.dart';
import 'app_loading_indicator.dart';
import 'app_shortcuts.dart';
import 'app_text_fields.dart';

/// A non-dismissible confirmation dialog for operations that require the user
/// to type an exact phrase before execution.
///
/// The operation owns its final authorization check. While it is running, all
/// dialog actions, Escape, and route back navigation are blocked.
class AppTypedConfirmationDialog extends StatefulWidget {
  const AppTypedConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmationPhrase,
    required this.confirmLabel,
    required this.progressMessage,
    required this.onConfirm,
    super.key,
    this.confirmVariant = AppButtonVariant.danger,
    this.dialogKey,
    this.fieldKey,
    this.cancelButtonKey,
    this.confirmButtonKey,
    this.progressKey,
  });

  final String title;
  final String message;
  final String confirmationPhrase;
  final String confirmLabel;
  final String progressMessage;
  final Future<void> Function() onConfirm;
  final AppButtonVariant confirmVariant;
  final Key? dialogKey;
  final Key? fieldKey;
  final Key? cancelButtonKey;
  final Key? confirmButtonKey;
  final Key? progressKey;

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmationPhrase,
    required String confirmLabel,
    required String progressMessage,
    required Future<void> Function() onConfirm,
    AppButtonVariant confirmVariant = AppButtonVariant.danger,
    Key? dialogKey,
    Key? fieldKey,
    Key? cancelButtonKey,
    Key? confirmButtonKey,
    Key? progressKey,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppTypedConfirmationDialog(
        title: title,
        message: message,
        confirmationPhrase: confirmationPhrase,
        confirmLabel: confirmLabel,
        progressMessage: progressMessage,
        onConfirm: onConfirm,
        confirmVariant: confirmVariant,
        dialogKey: dialogKey,
        fieldKey: fieldKey,
        cancelButtonKey: cancelButtonKey,
        confirmButtonKey: confirmButtonKey,
        progressKey: progressKey,
      ),
    );
    return result ?? false;
  }

  @override
  State<AppTypedConfirmationDialog> createState() =>
      _AppTypedConfirmationDialogState();
}

class _AppTypedConfirmationDialogState
    extends State<AppTypedConfirmationDialog> {
  final _confirmationController = TextEditingController();
  var _isBusy = false;
  String? _errorMessage;

  bool get _hasExactConfirmation =>
      _confirmationController.text == widget.confirmationPhrase;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  void _cancel() {
    if (_isBusy) return;
    Navigator.of(context).pop(false);
  }

  Future<void> _confirm() async {
    if (_isBusy || !_hasExactConfirmation) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is ServiceFailure
          ? error.message
          : 'تعذر إكمال العملية. لم يتم تغيير البيانات.';
      setState(() {
        _isBusy = false;
        _errorMessage = message;
      });
      AppToast.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: !_isBusy,
        child: AppShortcutScope(
          onEscape: _isBusy ? null : _cancel,
          child: Dialog(
            key: widget.dialogKey,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppDialogSizes.medium,
                maxHeight:
                    viewport.height * AppDialogSizes.maxHeightFactor,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      widget.confirmVariant == AppButtonVariant.danger
                          ? Icons.warning_amber_rounded
                          : Icons.restore_rounded,
                      color:
                          widget.confirmVariant == AppButtonVariant.danger
                          ? AppColors.danger
                          : AppColors.warning,
                      size: 46,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppInfoBanner(
                      message:
                          'اكتب العبارة التالية تماماً للمتابعة:\n${widget.confirmationPhrase}',
                      icon: Icons.keyboard_rounded,
                      foregroundColor:
                          widget.confirmVariant == AppButtonVariant.danger
                          ? AppColors.danger
                          : AppColors.warning,
                      backgroundColor:
                          widget.confirmVariant == AppButtonVariant.danger
                          ? AppColors.dangerSurface
                          : AppColors.warningSurface,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: widget.fieldKey,
                      controller: _confirmationController,
                      label: 'عبارة التأكيد',
                      hint: widget.confirmationPhrase,
                      icon: Icons.edit_rounded,
                      autofocus: true,
                      enabled: !_isBusy,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        } else {
                          setState(() {});
                        }
                      },
                      onSubmitted: (_) => _confirm(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppInfoBanner(
                        message: _errorMessage!,
                        icon: Icons.error_outline_rounded,
                        foregroundColor: AppColors.danger,
                        backgroundColor: AppColors.dangerSurface,
                      ),
                    ],
                    if (_isBusy) ...[
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
                        key: widget.progressKey,
                        container: true,
                        liveRegion: true,
                        label: widget.progressMessage,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppLoadingIndicator(
                              size: 28,
                              strokeWidth: 3,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                widget.progressMessage,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppButton(
                          key: widget.cancelButtonKey,
                          label: 'إلغاء',
                          icon: Icons.close_rounded,
                          onPressed: _isBusy ? null : _cancel,
                          variant: AppButtonVariant.secondary,
                          width: 160,
                        ),
                        AppButton(
                          key: widget.confirmButtonKey,
                          label: widget.confirmLabel,
                          icon: widget.confirmVariant ==
                                  AppButtonVariant.danger
                              ? Icons.delete_forever_rounded
                              : Icons.restore_rounded,
                          onPressed: !_isBusy && _hasExactConfirmation
                              ? _confirm
                              : null,
                          variant: widget.confirmVariant,
                          isLoading: _isBusy,
                          width: 210,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
