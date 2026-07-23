import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';

class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    required this.title,
    required this.body,
    super.key,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onBack;
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

    if (onBack == null) return page;

    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): onBack!,
        },
        child: page,
      ),
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
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F3),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E0D7)),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            _HeaderIconButton(
              icon: Icons.arrow_forward_rounded,
              semanticLabel: 'رجوع',
              onPressed: onBack!,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: const SizedBox.square(
            dimension: AppControlHeights.standard,
            child: Icon(Icons.arrow_forward_rounded),
          ),
        ),
      ),
    );
  }
}
