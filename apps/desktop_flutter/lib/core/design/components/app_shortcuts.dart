import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppKeyHoldGuard {
  AppKeyHoldGuard() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  final Set<LogicalKeyboardKey> _consumedKeys = {};

  bool runOnce({
    required Iterable<LogicalKeyboardKey> keys,
    required VoidCallback action,
  }) {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final activeKeys = keys.where(pressedKeys.contains).toSet();

    if (activeKeys.isEmpty) {
      action();
      return true;
    }

    if (activeKeys.any(_consumedKeys.contains)) return false;

    _consumedKeys.addAll(activeKeys);
    action();
    return true;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyUpEvent) {
      _consumedKeys.remove(event.logicalKey);
    }
    return false;
  }

  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _consumedKeys.clear();
  }
}

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
    this.onEscape,
  });

  final Widget child;
  final VoidCallback? onSearch;
  final VoidCallback? onSave;
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
