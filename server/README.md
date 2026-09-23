# OfflineAI School API

Production-oriented backend for authenticated synchronization and school services.

## Local PostgreSQL

From the repository root:

```bash
docker compose -f server/docker-compose.yml up -d
cd server
cp .env.example .env
npm install
npm run migrate
npm start
```

The API listens on `http://localhost:8080` by default.

## Required production environment

Set:

- `DATABASE_URL`
- `JWT_ACCESS_SECRET` — at least 32 random characters
- `JWT_REFRESH_SECRET` — a different secret, at least 32 random characters
- `ALLOWED_ORIGINS` — comma-separated web origins; mobile requests do not send an Origin header
- `NODE_ENV=production`
- `TRUST_PROXY=true` only when the deployment is actually behind a trusted reverse proxy

Keep secrets in the hosting provider's secret manager. Never commit them.

## Database

Run migrations before starting the application:

```bash
npm run migrate
```

For a first school deployment, seed an administrator:

```bash
npm run seed
```

with the `SEED_*` variables described in `.env.example`.

## Authentication

The API uses short-lived JWT access tokens and rotating refresh tokens stored server-side by hash. Learner synchronization requires a learner-role token and enforces that every synced attempt belongs to that authenticated learner.

## Endpoints

- `GET /health` — readiness check with database connectivity
- `POST /v1/auth/register` — optional learner self-registration, disabled by default
- `POST /v1/auth/login`
- `POST /v1/auth/refresh`
- `POST /v1/auth/logout`
- `GET /v1/auth/me`
- `DELETE /v1/auth/me/data` — deletes the authenticated learner's online account data
- `POST /v1/admin/users` — school admin provisioning
- `POST /v1/sync/attempts`
- `GET /v1/learners/:id/progress`

## Deployment requirements

Put the API behind HTTPS and a trusted reverse proxy/load balancer. Add a managed PostgreSQL deployment with encrypted backups, monitoring and restore drills. For multi-instance deployments, move the rate-limit store to shared infrastructure such as Redis.

Before handling real student data, complete the privacy, child-safety, data-retention, incident-response and security review documented in `docs/PRODUCTION-CHECKLIST.md`.
