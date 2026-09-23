# OfflineAI School — Pilot Runbook

## Pilot build

The primary pilot target is Android. The CI workflow generates the Android platform files, builds a release APK, and uploads it as the `offline-ai-school-android` artifact.

For local development:

```bash
flutter pub get
flutter create --platforms=android --org org.offlineaischool .
flutter run
```

## Learner flow to demonstrate

1. Open OfflineAI School.
2. Complete learner profile.
3. Complete the five-question diagnostic.
4. Open Grade 6 Mathematics.
5. Study Fractions, then complete practice.
6. Repeat practice and observe topic mastery change.
7. Open Decimals and Percentages after the prerequisite path is demonstrated.
8. Open Ask OfflineAI and ask a curriculum question.
9. Open Virtual Science Lab and change mass/volume to inspect density.
10. Open My Progress to review topic states and recommendations.
11. Open Teacher Dashboard to review practice evidence.
12. Turn connectivity off, complete a practice question, and confirm the attempt remains pending.
13. Restore connectivity and run Sync; the queued attempt should be marked synced only after a successful send.

## Pilot data principles

- Keep learner data to the minimum needed for the pilot.
- Use stable learner IDs and client IDs for duplicate-safe synchronization.
- Diagnostic attempts are kept separate from mastery calculations.
- Do not expose the sync server publicly until authentication, HTTPS, access controls, and rate limiting are configured.
- Treat current teacher insights as pilot evidence, not a replacement for teacher judgement.

## Current MVP scope

- Grade 6 Mathematics: Fractions, Decimals, Percentages.
- Grade 6 Science and Technology: Matter, Density.
- Offline local storage.
- Adaptive recommendations and evidence-aware mastery.
- Offline tutor explanations for the supported MVP topics.
- Density investigation simulation.
- Teacher practice insights.
- HTTP synchronization with duplicate-safe server storage.

## Production work still required

Before a public deployment, add authentication/authorization, secure transport and secret management, deployment monitoring, stronger misconception models, broader curriculum coverage, more languages, real class-level aggregation, and device-level integration testing.
