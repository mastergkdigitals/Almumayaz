import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows runner exposes Almumayaz product metadata', () {
    final cmake = _readProjectFile('windows/CMakeLists.txt');
    final resources = _readProjectFile('windows/runner/Runner.rc');

    expect(cmake, contains('project(Almumayaz LANGUAGES CXX)'));
    expect(cmake, contains('set(BINARY_NAME "Almumayaz")'));
    expect(resources, contains('VALUE "CompanyName", "Almumayaz"'));
    expect(resources, contains('VALUE "FileDescription", "Almumayaz"'));
    expect(resources, contains('VALUE "OriginalFilename", "Almumayaz.exe"'));
    expect(resources, contains('VALUE "ProductName", "Almumayaz"'));
  });

  test('Windows runner preserves minimum, aspect, maximize, and DPI rules', () {
    final runner = _readProjectFile('windows/runner/win32_window.cpp');
    final entrypoint = _readProjectFile('windows/runner/main.cpp');
    final manifest = _readProjectFile('windows/runner/runner.exe.manifest');

    expect(runner, contains('constexpr int kMinimumWindowWidth = 1280;'));
    expect(runner, contains('constexpr int kMinimumWindowHeight = 720;'));
    expect(runner, contains('constexpr int kWindowAspectWidth = 16;'));
    expect(runner, contains('constexpr int kWindowAspectHeight = 9;'));
    expect(runner, contains('case WM_GETMINMAXINFO:'));
    expect(runner, contains('case WM_SIZING:'));
    expect(runner, contains('if (!IsZoomed(hwnd)'));
    expect(
      runner,
      contains('return ShowWindow(window_handle_, SW_SHOWMAXIMIZED);'),
    );
    expect(runner, contains('case WM_DPICHANGED:'));
    expect(entrypoint, contains('Win32Window::Size size(1280, 720);'));
    expect(manifest, contains('PerMonitorV2'));
    expect(manifest, contains('Windows 10 and Windows 11'));
  });

  test('Windows runner accepts the configured application title', () {
    final entrypoint = _readProjectFile('windows/runner/main.cpp');
    final window = _readProjectFile('windows/runner/flutter_window.cpp');
    final main = _readProjectFile('lib/main.dart');

    expect(entrypoint, contains('L"Almumayaz ERP"'));
    expect(window, contains('"almumayaz/native_window"'));
    expect(window, contains('call.method_name() != "setTitle"'));
    expect(window, contains('SetWindowTextW(GetHandle()'));
    expect(main, contains('configuration.applicationTitle'));
    expect(main, contains('MethodChannelNativeWindowService'));
  });
}

String _readProjectFile(String relativePath) {
  final local = File(relativePath);
  if (local.existsSync()) return local.readAsStringSync();

  final fromRepositoryRoot = File('apps/desktop_flutter/$relativePath');
  if (fromRepositoryRoot.existsSync()) {
    return fromRepositoryRoot.readAsStringSync();
  }

  throw StateError('Could not locate $relativePath from ${Directory.current}');
}
