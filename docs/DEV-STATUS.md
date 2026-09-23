# OfflineAI School — Development Status

## Current milestone

**Production hardening / release-candidate stage**

## Implemented

### Learner app
- Figma MVP across core learner, teacher, lab and sync flows.
- Flutter application shell and learner onboarding.
- Five-question diagnostic assessment.
- Grade 6 Mathematics: Fractions, Decimals, Percentages.
- Grade 6 Science & Technology: Matter, Density.
- Local SQLite persistence.
- Learner identity linked to learning attempts.
- Diagnostic/practice separation.
- Durable offline sync queue.
- Adaptive recommendations and evidence-aware mastery.
- Topic-specific offline tutor.
- Question-level duration capture.
- Density virtual laboratory.
- School-scoped teacher learning overview.
- Secure learner account screen.
- Secure session storage with token refresh.
- Online learner account/data deletion.

### Backend
- PostgreSQL schema and migrations.
- JWT access tokens.
- Rotating server-tracked refresh tokens.
- Role-based authorization.
- School-scoped teacher/admin access.
- Authenticated learner-only synchronization.
- Duplicate-safe client IDs.
- Request validation and body limits.
- Helmet security headers.
- Browser CORS allowlist.
- Rate limiting baseline.
- Security audit event storage.
- Health/readiness endpoint.
- Admin user provisioning.
- Local Docker/PostgreSQL environment.
- Production container definition.

### Engineering
- Flutter analysis gate.
- Automated app regression tests.
- API integration tests against PostgreSQL.
- Android release APK build.
- Android App Bundle build.
- Android emulator onboarding smoke test.
- Dependabot configuration.
- CodeQL configuration.
- Production deployment/security/privacy documentation.

## Remaining production acceptance gates

- Configure and deploy the real production API with HTTPS.
- Configure managed PostgreSQL, encrypted backups and restore drills.
- Configure production release signing and Play App Signing.
- Complete the physical-device test matrix, including low-end Android and unstable connectivity.
- Complete external security review.
- Configure crash/error/uptime monitoring.
- Validate Zimbabwe curriculum content with qualified educators.
- Validate safeguarding, consent, data retention and final privacy documents.
- Replace the pilot teacher view with the complete school/class/learner workflow.
- Add stronger misconception detection and intervention tracking.
- Add broader curriculum and language coverage.
- Add production AI gateway and model governance.
- Complete staged school pilot and operational acceptance.

## Rule

Do not call the product publicly production-ready until the unchecked acceptance gates are closed with evidence.
