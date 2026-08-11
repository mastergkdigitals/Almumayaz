import 'package:flutter/material.dart';

import '../core/app_state/app_store.dart';
import '../core/config/app_configuration.dart';
import '../core/design/app_theme.dart';
import '../core/design/components/app_shortcuts.dart';
import '../core/printing/document_output_scope.dart';
import '../core/responsive/responsive_shell.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/session_activity_guard.dart';

final almumayazNavigatorKey = GlobalKey<NavigatorState>();

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
      child: Builder(
        builder: (storeContext) {
          final output = AppStoreScope.of(
            storeContext,
            listen: false,
          ).services.documentOutput;
          return DocumentOutputScope(
            printService: output,
            exportService: output,
            child: AppConfigurationScope(
              configuration: effectiveConfiguration,
              child: MaterialApp(
                navigatorKey: almumayazNavigatorKey,
                title: effectiveConfiguration.applicationTitle,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                locale: const Locale('ar', 'IQ'),
                builder: (context, child) => Directionality(
                  textDirection: TextDirection.rtl,
                  // MaterialApp.builder sits above the Navigator overlay.
                  // The session-lock editor needs this local Overlay ancestor.
                  child: Overlay.wrap(
                    child: SessionActivityGuard(
                      onRequireSignIn: () async {
                        try {
                          await AppStoreScope.of(
                            storeContext,
                            listen: false,
                          ).signOut();
                        } on Object {
                          // A remotely expired session may already be absent.
                          // Returning to sign-in must remain possible.
                        } finally {
                          almumayazNavigatorKey.currentState
                              ?.pushAndRemoveUntil(
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
        },
      ),
    );
  }
}
