# OfflineAI School — Production Deployment Guide

## 1. Infrastructure

Deploy the API as a container behind an HTTPS reverse proxy or load balancer.

Recommended logical layout:

- managed PostgreSQL database;
- API container(s);
- TLS termination at the edge;
- centralized logs and uptime monitoring;
- encrypted database backups;
- separate staging and production environments.

## 2. Database

Set a production `DATABASE_URL` and run:

```bash
cd server
npm install
npm run migrate
```

Do not use the local Docker database for real learner data.

Run a restore drill before the first school rollout and periodically afterwards.

## 3. Secrets

Set these through the hosting provider's secret manager:

- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`
- `DATABASE_URL`

Both JWT secrets must be long, random and different.

Never commit production `.env` files, signing keys, service credentials or AI provider keys.

## 4. School provisioning

Create the first school and administrator with the seed command, then use the administrator account to provision teacher and learner accounts through the protected admin endpoint.

Keep `ALLOW_SELF_REGISTRATION=false` for managed school deployments unless there is an approved onboarding process.

## 5. Mobile configuration

Build the Android app with the production HTTPS API endpoint:

```bash
flutter build apk --release --dart-define=OFFLINE_AI_API_URL=https://api.example.org
```

For local development only, an explicit insecure-HTTP build flag can be used:

```bash
flutter run --dart-define=OFFLINE_AI_API_URL=http://10.0.2.2:8080 --dart-define=ALLOW_INSECURE_HTTP=true
```

Do not use the insecure flag for production.

## 6. Android release

The CI workflow validates:

- Flutter analysis;
- automated tests;
- Android emulator smoke testing;
- Android APK release build;
- Android App Bundle release build.

Before store release, configure release signing and Play App Signing outside source control.

## 7. Operational gates

Before real student data is loaded:

- complete the privacy/legal review;
- approve data retention and deletion procedures;
- validate curriculum content with qualified educators;
- complete the security review;
- run low-end Android and unstable-network field tests;
- enable crash/error/uptime monitoring;
- verify backup restoration;
- document an incident-response contact.

## 8. Staging to production

Use:

```
Development → CI → Staging → School Pilot → Production
```

Do not point development or staging clients at the production database.
