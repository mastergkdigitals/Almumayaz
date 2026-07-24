import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppKeyboardScope extends StatelessWidget {
  const AppKeyboardScope({
    required this.child,
    super.key,
  });

  final Widget child;

  void _ignoreDirectionalNavigation() {}

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            _ignoreDirectionalNavigation,
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            _ignoreDirectionalNavigation,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            _ignoreDirectionalNavigation,
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            _ignoreDirectionalNavigation,
      },
      child: child,
    );
  }
}

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
    final bindings = <ShortcutActivator, VoidCallback>{};

    void addBinding(ShortcutActivator activator, VoidCallback? callback) {
      if (callback != null) bindings[activator] = callback;
    }

    addBinding(
      const SingleActivator(LogicalKeyboardKey.keyF, control: true),
      onSearch,
    );
    addBinding(
      const SingleActivator(LogicalKeyboardKey.keyS, control: true),
      onSave,
    );
    addBinding(
      const SingleActivator(LogicalKeyboardKey.keyN, control: true),
      onNew,
    );
    addBinding(const SingleActivator(LogicalKeyboardKey.f5), onRefresh);
    addBinding(const SingleActivator(LogicalKeyboardKey.escape), onEscape);

    if (bindings.isEmpty) return child;

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(
        autofocus: true,
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
