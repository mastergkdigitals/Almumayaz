# Flutter internal and customer editions

Almumayaz uses one repository and one Flutter application. Customer editions
are release configurations of that application; they are not copied project
folders.

## Profiles

| Profile | Purpose | Design System |
| --- | --- | --- |
| `internal` | Development, visual review, and complete feature validation | Visible |
| `customer` | Customer-specific modules and branding | Always hidden |

The application enforces the last rule in Dart. Even an incorrect
`SHOW_DESIGN_SYSTEM=true` define cannot expose the Design System when
`APP_EDITION=customer`.

## Configuration

Copy `apps/desktop_flutter/config/customer.example.json` to a customer-owned
configuration file and update these values:

| Define | Meaning |
| --- | --- |
| `APP_EDITION` | `internal` or `customer` |
| `SHOW_DESIGN_SYSTEM` | Development convenience; must be `false` for customers |
| `ENABLED_MODULES` | Comma-separated module IDs |
| `APP_TITLE` | Flutter title and native Windows window title |
| `COMPANY_NAME` | Name shown on the company dashboard card |
| `COMPANY_LOGO_ASSET` | Optional bundled asset path shown on the company card |

Available module IDs are `purchases`, `sales`, `cashbox`, `parties`,
`company`, `warehouses`, `reports`, `settings`, and `about`.

Customer configuration files may stay outside the repository. This avoids
committing customer-specific information while keeping a single codebase.

For a custom logo, place the image under
`apps/desktop_flutter/assets/png/` before building, then set
`COMPANY_LOGO_ASSET` to its Flutter asset path, for example
`assets/png/customer-logo.png`. The whole PNG directory is bundled, so this
does not require another application folder or a source-code change.

## Build commands

Run from the repository root in PowerShell:

```powershell
.\tools\release\build_internal_windows.ps1

.\tools\release\build_customer_windows.ps1 `
  -ConfigPath C:\AlmumayazConfigs\customer-a.json
```

Both commands produce
`apps/desktop_flutter/build/windows/x64/runner/Release/Almumayaz.exe`.
The Dart package deliberately remains `erp`; changing it would only create
import churn and does not affect the customer-visible executable or metadata.
The executable metadata remains the Almumayaz product identity, while
`APP_TITLE`, company name, logo, and enabled modules are edition-specific.

GitHub Actions verifies the common test suite and creates separate internal
and customer-example Windows ZIP artifacts. A real customer build should use
its private configuration and logo with the same customer build script.

## Verification before delivery

From `apps/desktop_flutter`, verify analysis and widget tests. Run the
backend-free workflow smoke test on Windows with:

```powershell
flutter test integration_test\release_profile_smoke_test.dart
```

Check the restored window at 1280×720, 1366×768, 1920×1080, and 2560×1440.
Also check Windows scale settings at 100%, 125%, 150%, and 200%. The native
runner declares Per-Monitor V2 DPI awareness, keeps restored resizing at 16:9,
and leaves maximized sizing to the active monitor.

This Flutter client still uses demo repositories and service adapters. Do not
deliver it as a production accounting system until the API, database,
security, persistence, and release acceptance phases are complete.
