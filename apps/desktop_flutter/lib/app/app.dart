import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import '../core/design/components/app_shortcuts.dart';
import '../core/responsive/responsive_shell.dart';
import '../features/auth/presentation/login_screen.dart';

class AlmumayazApp extends StatelessWidget {
  const AlmumayazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المميز ERP',
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
    );
  }
}
