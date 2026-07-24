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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.screenTitle,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (onBack != null)
            Align(
              alignment: Alignment.centerRight,
              child: AppHeaderIconButton(
                key: const Key('appScreenBackButton'),
                tooltipKey: const Key('appScreenBackTooltip'),
                icon: Icons.arrow_back_rounded,
                tooltip: 'رجوع',
                onPressed: onBack,
              ),
            ),
          if (actions.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final action in actions)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.sm,
                      ),
                      child: action,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
