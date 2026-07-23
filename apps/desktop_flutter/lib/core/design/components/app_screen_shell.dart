import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_header_button.dart';
import 'app_shortcuts.dart';

class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    required this.title,
    required this.body,
    super.key,
    this.subtitle,
    this.onBack,
    this.onSearch,
    this.onSave,
    this.onNew,
    this.onRefresh,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final VoidCallback? onSave;
  final VoidCallback? onNew;
  final VoidCallback? onRefresh;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppScreenHeader(
            title: title,
            subtitle: subtitle,
            onBack: onBack,
            actions: actions,
          ),
          Expanded(child: body),
        ],
      ),
    );

    return AppShortcutScope(
      onEscape: onBack,
      onSearch: onSearch,
      onSave: onSave,
      onNew: onNew,
      onRefresh: onRefresh,
      child: page,
    );
  }
}

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppHeaderSizes.screen,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.headerBorder),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            AppHeaderIconButton(
              icon: Icons.arrow_forward_rounded,
              tooltip: 'رجوع',
              size: AppControlHeights.standard,
              onPressed: onBack,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.screenTitle),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          for (final action in actions)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: action,
            ),
        ],
      ),
    );
  }
}
