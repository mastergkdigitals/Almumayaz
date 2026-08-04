# Almumayaz Flutter desktop

Arabic RTL Flutter client for Windows 10 and later. The Dart package remains
named `erp` so existing imports stay stable, while the Windows product and
executable are named `Almumayaz`.

## Build profiles

The application uses one source tree for both editions:

- `internal`: all configured modules plus the developer Design System.
- `customer`: only configured modules; the Design System is always hidden.

Build configuration is supplied with `--dart-define-from-file`. Ready-to-use
examples live in [`config/internal.json`](config/internal.json) and
[`config/customer.example.json`](config/customer.example.json). From the
repository root, use:

```powershell
.\tools\release\build_internal_windows.ps1
.\tools\release\build_customer_windows.ps1 `
  -ConfigPath .\apps\desktop_flutter\config\customer.example.json
```

The release executable is
`build/windows/x64/runner/Release/Almumayaz.exe`.

See [`../../docs/deployment/flutter_customer_editions.md`](../../docs/deployment/flutter_customer_editions.md)
for configuration, validation, and customer-edition guidance.

## Verification

Run analysis and widget tests from this directory. The cross-screen,
backend-free workflow smoke test is in `integration_test/` and can be run on
Windows as documented in the customer-editions guide.
