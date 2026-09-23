# OfflineAI School — Development Status

## Current milestone
Building the functional MVP for a school pilot.

## Completed
- Figma MVP designed across the core learner, teacher, lab, and sync flows.
- Flutter application shell and learner onboarding.
- Local SQLite persistence.
- Learner identity stored with learning attempts.
- Diagnostic vs practice attempt separation.
- Offline pending-attempt queue.
- Connectivity abstraction.
- HTTP synchronization backend.
- Idempotent server storage using client IDs.
- Curriculum prerequisite engine.
- Adaptive recommendation engine.
- Evidence-aware mastery engine using recency, difficulty, consistency, recent accuracy, and evidence confidence.
- Grade 6 Mathematics content: Fractions, Decimals, Percentages.
- Grade 6 Science and Technology content: Matter, Density.
- Regression tests for adaptive logic, curriculum logic, database persistence, diagnostics, and synchronization.
- CI workflow with Flutter analyze/test.

## Current engineering gate
CI has been repeatedly triggered while fixes land. The repository should only be treated as green after the latest run for the current main commit completes successfully.

## Known next milestones
1. Verify latest CI fully passes.
2. Add stronger mastery/misconception tracking.
3. Make curriculum progress learner-specific across multiple topics.
4. Improve adaptive question selection using topic history and difficulty.
5. Build a real Science & Technology learning flow and richer density simulation.
6. Strengthen the offline AI tutor with curriculum-aware explanations and guardrails.
7. Connect the teacher dashboard to synchronized learner data instead of demo values.
8. Add robust sync retry/backoff, duplicate reporting, and production authentication.
9. Package a pilot build for a Zimbabwean school.
10. Prepare pilot metrics, demo, pitch deck, and commercial outreach.

## Product principle
A student's potential should not depend on their internet connection.

## Repository
https://github.com/klarah100/Offline-AI-school
