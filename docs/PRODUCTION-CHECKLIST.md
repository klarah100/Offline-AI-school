# OfflineAI School — Production Checklist

## Engineering gates

- [x] Flutter static analysis passes.
- [x] Automated app tests pass.
- [x] Android release APK builds in CI.
- [x] Android App Bundle builds in CI.
- [x] PostgreSQL API tests run in CI.
- [x] Authenticated learner sync implemented.
- [x] Refresh-token rotation implemented.
- [x] Learner-to-account identity linking implemented.
- [x] Server-side learner scope enforcement implemented.
- [x] Audit log storage implemented.
- [x] Data deletion endpoint implemented.
- [x] Secure client token storage implemented.
- [ ] Physical-device test matrix completed.
- [ ] External security review completed.
- [ ] Production domain and TLS deployed.
- [ ] Managed PostgreSQL backups and restore drill completed.
- [ ] Shared rate-limit storage configured for multi-instance deployment.
- [ ] Release signing and Play App Signing configured.
- [ ] Crash/error/uptime monitoring configured.

## Product and education gates

- [ ] Zimbabwe curriculum content reviewed by qualified educators.
- [ ] Diagnostic content validated separately from mastery evidence.
- [ ] Misconception taxonomy validated.
- [ ] Teacher workflows tested with real teachers.
- [ ] School/class roster model finalized.
- [ ] Learner, teacher and administrator onboarding finalized.
- [ ] Accessibility review completed.
- [ ] Low-end Android device and unstable-network field tests completed.
- [ ] Pilot data-retention period approved.
- [ ] Safeguarding and child-protection procedures approved.

## Launch gate

Do not label the system production-ready for real student data until every unchecked security, privacy, deployment and operational gate has an owner and documented acceptance evidence.
