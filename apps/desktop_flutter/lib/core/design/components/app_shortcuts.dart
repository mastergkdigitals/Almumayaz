import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppShortcutScope extends StatelessWidget {
  const AppShortcutScope({
    required this.child,
    super.key,
    this.onSearch,
    this.onSave,
    this.onNew,
    this.onRefresh,
    this.onEscape,
  });

  final Widget child;
  final VoidCallback? onSearch;
  final VoidCallback? onSave;
  final VoidCallback? onNew;
  final VoidCallback? onRefresh;
  final VoidCallback? onEscape;

  @override
  Widget build(BuildContext context) {
    final bindings = <ShortcutActivator, VoidCallback>{
      if (onSearch != null)
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            onSearch!,
      if (onSave != null)
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave!,
      if (onNew != null)
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): onNew!,
      if (onRefresh != null)
        const SingleActivator(LogicalKeyboardKey.f5): onRefresh!,
      if (onEscape != null)
        const SingleActivator(LogicalKeyboardKey.escape): onEscape!,
    };

    if (bindings.isEmpty) return child;

    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: bindings,
        child: child,
      ),
    );
  }
}

abstract final class AppFocusTraversal {
  static void next(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  static void previous(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}
