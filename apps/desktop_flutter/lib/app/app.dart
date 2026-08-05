import 'package:flutter/material.dart';

import '../core/app_state/app_store.dart';
import '../core/config/app_configuration.dart';
import '../core/design/app_theme.dart';
import '../core/design/components/app_shortcuts.dart';
import '../core/responsive/responsive_shell.dart';
import '../features/auth/presentation/login_screen.dart';

class AlmumayazApp extends StatelessWidget {
  const AlmumayazApp({super.key, this.configuration});

  final AppConfiguration? configuration;

  @override
  Widget build(BuildContext context) {
    final effectiveConfiguration =
        configuration ?? AppConfiguration.fromEnvironment();

    return AppStoreProvider(
      child: AppConfigurationScope(
        configuration: effectiveConfiguration,
        child: MaterialApp(
          title: effectiveConfiguration.applicationTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: const Locale('ar', 'IQ'),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: AppKeyboardScope(
              child: ResponsiveDesktopShell(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
