# OfflineAI School

**AI-powered education that works even when the internet doesn't.**

OfflineAI School is an offline-first learning platform designed for learners and schools operating with unreliable or expensive internet access.

## Current product

The functional Android MVP includes:

- learner onboarding and diagnostic assessment;
- Grade 6 Mathematics: Fractions, Decimals, Percentages;
- Grade 6 Science & Technology: Matter and Density;
- local SQLite learning persistence;
- adaptive recommendations and evidence-aware mastery;
- offline curriculum tutor;
- virtual density laboratory;
- authenticated learner accounts;
- secure token storage on the device;
- protected synchronization with learner scoping and duplicate-safe client IDs;
- school-scoped teacher learning overview;
- learner account/data deletion;
- production-focused PostgreSQL API;
- automated Flutter, Android, API, and emulator CI gates.

## Product principle

> A student's potential should not depend on their internet connection.

## Architecture

```
Android / future web clients
          │
      Local SQLite
          │
      Offline queue
          │
        HTTPS
          │
  Authenticated API
          │
      PostgreSQL
          │
 ┌────────┴────────┐
 │                 │
Teacher data     AI gateway
and school       (future)
services
```

The offline path remains the primary learning path. Online services add synchronization, school coordination, and heavier AI capabilities.

## Development

```bash
flutter pub get
flutter run
```

For an Android release build with a configured production API:

```bash
flutter build apk --release --dart-define=OFFLINE_AI_API_URL=https://api.example.org
flutter build appbundle --release --dart-define=OFFLINE_AI_API_URL=https://api.example.org
```

The repository CI also runs an Android emulator onboarding smoke test.

## Production backend

The API is under `server/` and uses PostgreSQL for server-side data.

See:

- `docs/PRODUCTION-CHECKLIST.md`
- `docs/PRODUCTION-DEPLOYMENT.md`
- `docs/SECURITY.md`
- `docs/PRIVACY-NOTICE-DRAFT.md`
- `docs/PILOT-RUNBOOK.md`
- `server/README.md`

## Important release note

This repository now contains a production-oriented security and deployment baseline, but a public launch with real student data still requires the unchecked gates in `docs/PRODUCTION-CHECKLIST.md`, including production infrastructure, release signing, monitoring, external security review, educator validation, privacy approval, and field testing on target low-connectivity devices.

## Repository

https://github.com/klarah100/Offline-AI-school
