import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/app_state/app_store.dart';
import 'core/config/app_configuration.dart';
import 'core/platform/native_window_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final configuration = AppConfiguration.fromEnvironment();
  runApp(
    AlmumayazApp(
      configuration: configuration,
      store: AppStore.desktop(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      const MethodChannelNativeWindowService().setTitle(
        configuration.applicationTitle,
      ),
    );
  });
}
