# OfflineAI School — Security Baseline

## Implemented

- JWT access tokens are short lived.
- Refresh tokens are rotated and stored server-side by hash.
- Learner sync is restricted to the authenticated learner identity.
- Teacher/admin progress access is restricted to the same school.
- Request bodies are size-limited and validated with Zod.
- Authentication endpoints are rate limited.
- Helmet security headers are enabled.
- Browser origins are allowlisted.
- SQL queries use parameterized values.
- Security-sensitive lifecycle events are written to audit logs.
- Client tokens are stored with platform secure storage.
- Learner online data deletion is exposed through an authenticated endpoint.
- Production secrets are excluded from Git.

## Required before public launch

- Deploy behind HTTPS with a trusted reverse proxy.
- Use a managed PostgreSQL service with encryption, backups and restore drills.
- Move rate limiting to shared storage such as Redis before horizontal scaling.
- Rotate JWT secrets through a secrets manager.
- Run an external mobile/API security review using OWASP MASVS as the test baseline.
- Enable dependency scanning and automated vulnerability alerts.
- Establish an incident response contact and breach-response runbook.
- Test account takeover, refresh-token replay, authorization boundaries and rate limits.
- Test offline sync after app termination, clock skew and repeated network loss.
