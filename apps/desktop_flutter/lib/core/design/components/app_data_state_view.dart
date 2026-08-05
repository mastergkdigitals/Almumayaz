import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import 'app_feedback.dart';

typedef AppDataBuilder<T extends Object> = Widget Function(
  BuildContext context,
  T data,
);

/// Maps a repository [AppDataState] to the shared application state panels.
///
/// Ready data is passed to [dataBuilder]. Loading, empty, missing-reference,
/// and error states keep one consistent presentation throughout the app.
class AppDataStateView<T extends Object> extends StatelessWidget {
  const AppDataStateView({
    required this.state,
    required this.dataBuilder,
    super.key,
    this.loadingTitle = 'جاري التحميل',
    this.loadingMessage = 'يرجى الانتظار قليلاً.',
    this.emptyTitle = 'لا توجد بيانات',
    this.emptyMessage = 'لا توجد سجلات لعرضها حالياً.',
    this.missingReferenceTitle = 'مرجع البيانات غير متاح',
    this.missingReferenceMessage = 'تعذر العثور على البيانات المرتبطة.',
    this.errorTitle = 'تعذر تحميل البيانات',
    this.errorMessage = 'حدث خطأ غير متوقع. حاول مرة أخرى.',
    this.emptyActionLabel,
    this.onEmptyAction,
    this.missingReferenceActionLabel,
    this.onMissingReferenceAction,
    this.errorActionLabel = 'إعادة المحاولة',
    this.onRetry,
    this.loadingStateKey,
    this.emptyStateKey,
    this.missingReferenceStateKey,
    this.errorStateKey,
    this.centerStatePanels = true,
  });

  final AppDataState<T> state;
  final AppDataBuilder<T> dataBuilder;

  final String loadingTitle;
  final String loadingMessage;
  final String emptyTitle;
  final String emptyMessage;
  final String missingReferenceTitle;
  final String missingReferenceMessage;
  final String errorTitle;
  final String errorMessage;

  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String? missingReferenceActionLabel;
  final VoidCallback? onMissingReferenceAction;
  final String? errorActionLabel;
  final VoidCallback? onRetry;

  final Key? loadingStateKey;
  final Key? emptyStateKey;
  final Key? missingReferenceStateKey;
  final Key? errorStateKey;
  final bool centerStatePanels;

  @override
  Widget build(BuildContext context) {
    if (state.status == AppDataStatus.ready) {
      return dataBuilder(context, state.data!);
    }

    final panel = switch (state.status) {
      AppDataStatus.loading => AppStatePanel(
          key: loadingStateKey,
          type: AppStateType.loading,
          title: loadingTitle,
          message: state.message ?? loadingMessage,
        ),
      AppDataStatus.empty => AppStatePanel(
          key: emptyStateKey,
          type: AppStateType.empty,
          title: emptyTitle,
          message: state.message ?? emptyMessage,
          actionLabel: emptyActionLabel,
          onAction: onEmptyAction,
        ),
      AppDataStatus.missingReference => AppStatePanel(
          key: missingReferenceStateKey,
          type: AppStateType.missingReference,
          title: missingReferenceTitle,
          message: state.message ?? missingReferenceMessage,
          actionLabel: missingReferenceActionLabel,
          onAction: onMissingReferenceAction,
        ),
      AppDataStatus.error => AppStatePanel(
          key: errorStateKey,
          type: AppStateType.error,
          title: errorTitle,
          message: state.message ?? errorMessage,
          actionLabel: onRetry == null ? null : errorActionLabel,
          onAction: onRetry,
        ),
      AppDataStatus.ready => throw StateError(
          'Ready AppDataState must contain data.',
        ),
    };

    return centerStatePanels ? Center(child: panel) : panel;
  }
}
