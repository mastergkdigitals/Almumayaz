import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_loading_indicator.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
    this.message = 'جاري التحميل',
  });

  final bool isLoading;
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: AppColors.textPrimary.withAlpha(72),
                child: Center(
                  child: Semantics(
                    liveRegion: true,
                    label: message,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 180),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLoadingIndicator(
                            size: 40,
                            strokeWidth: 4,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            message,
                            style: AppTypography.sectionTitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
