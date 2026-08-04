# Almumayaz ERP

New Arabic RTL Windows desktop ERP currently in the Flutter design and workflow
stage. The shared Design System and the main application screens use organized
demo data while their fields, calculations, keyboard behavior, printing flows,
and business rules are finalized.

The Express API and PostgreSQL database have not been implemented yet, so this
repository must not currently be described or distributed as a production-ready
business system.

## Current stage

- Flutter Windows screens and shared Design System are under active development.
- Current records are demo data used to validate the completed workflows.
- Demo data will be isolated behind repositories and replaced module by module.
- Backend, database, authentication, permissions, audit, and real persistence
  will follow the approved product blueprint.
- The legacy `AlmumayazDev` repository is a visual and behavioral reference only.

## Target stack

- Flutter Windows desktop client
- Express + TypeScript API
- PostgreSQL database
- Arabic RTL with Tajawal
- PDF, printing, and Excel export

## Architecture

```text
Flutter Windows client
        |
        v
Express /api/v1
        |
        v
PostgreSQL
```

This repository is a new application and does not depend on the legacy
`AlmumayazDev` codebase.

The approved product and business rules are documented in
[`docs/business_rules/app_blueprint_ar.md`](docs/business_rules/app_blueprint_ar.md).
