import 'package:flutter/material.dart';

import '../core/app_state/app_store.dart';
import '../core/config/app_configuration.dart';
import '../core/design/app_theme.dart';
import '../core/design/components/app_shortcuts.dart';
import '../core/printing/document_output_scope.dart';
import '../core/responsive/responsive_shell.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/session_activity_guard.dart';

GlobalKey<NavigatorState> almumayazNavigatorKey =
    GlobalKey<NavigatorState>();

class AlmumayazApp extends StatelessWidget {
  const AlmumayazApp({super.key, this.configuration, this.store});

  final AppConfiguration? configuration;
  final AppStore? store;

  @override
  Widget build(BuildContext context) {
    final effectiveConfiguration =
        configuration ?? AppConfiguration.fromEnvironment();

    return AppStoreProvider(
      store: store,
      internalToolsEnabled:
          effectiveConfiguration.edition == AppEdition.internal,
      child: Builder(
        builder: (storeContext) {
          final effectiveStore = AppStoreScope.of(
            storeContext,
            listen: false,
          );
          return _AppCompositionHost(
            store: effectiveStore,
            configuration: effectiveConfiguration,
          );
        },
      ),
    );
  }
}

/// Rebinds composition-owned adapters and disposes every cached feature route
/// when a whole-data replacement succeeds.
class _AppCompositionHost extends StatefulWidget {
  const _AppCompositionHost({
    required this.store,
    required this.configuration,
  });

  final AppStore store;
  final AppConfiguration configuration;

  @override
  State<_AppCompositionHost> createState() => _AppCompositionHostState();
}

class _AppCompositionHostState extends State<_AppCompositionHost> {
  late int _dataGeneration;

  @override
  void initState() {
    super.initState();
    _dataGeneration = widget.store.dataGeneration;
    widget.store.addListener(_handleStoreChange);
  }

  @override
  void didUpdateWidget(_AppCompositionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.store, widget.store)) return;
    oldWidget.store.removeListener(_handleStoreChange);
    _dataGeneration = widget.store.dataGeneration;
    widget.store.addListener(_handleStoreChange);
  }

  void _handleStoreChange() {
    final generation = widget.store.dataGeneration;
    if (generation == _dataGeneration || !mounted) return;
    _dataGeneration = generation;
    // A fresh navigator identity disposes cached feature routes/controllers
    // and makes the new MaterialApp start directly at LoginScreen.
    almumayazNavigatorKey = GlobalKey<NavigatorState>();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.store.dataGeneration == generation) {
        // The old keyed SessionActivityGuard may dispose after the new guard
        // initializes. Reassert ownership for the live generation so its
        // disposal cannot leave idle monitoring suspended.
        widget.store.resumeIdleMonitoring();
      }
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_handleStoreChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final output = widget.store.services.documentOutput;
    return DocumentOutputScope(
      key: ValueKey<int>(_dataGeneration),
      printService: output,
      exportService: output,
      child: AppConfigurationScope(
        configuration: widget.configuration,
        child: MaterialApp(
          key: ValueKey<String>('app-data-$_dataGeneration'),
          navigatorKey: almumayazNavigatorKey,
          title: widget.configuration.applicationTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: const Locale('ar', 'IQ'),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: Overlay.wrap(
              child: SessionActivityGuard(
                onRequireSignIn: () async {
                  try {
                    await widget.store.signOut();
                  } on Object {
                    // A remotely expired session may already be absent.
                  } finally {
                    almumayazNavigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                      (_) => false,
                    );
                  }
                },
                child: AppKeyboardScope(
                  child: ResponsiveDesktopShell(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
