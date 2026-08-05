import 'dart:io';

import 'package:flutter/services.dart';

abstract interface class NativeWindowService {
  Future<void> setTitle(String title);
}

class MethodChannelNativeWindowService implements NativeWindowService {
  const MethodChannelNativeWindowService();

  static const _channel = MethodChannel('almumayaz/native_window');

  @override
  Future<void> setTitle(String title) async {
    final normalizedTitle = title.trim();
    if (!Platform.isWindows || normalizedTitle.isEmpty) return;

    try {
      await _channel.invokeMethod<void>('setTitle', normalizedTitle);
    } on MissingPluginException {
      // Widget/unit tests do not start the native Windows runner.
    } on PlatformException {
      // Keep startup usable if Windows rejects a title update.
    }
  }
}
