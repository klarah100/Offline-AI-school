# OfflineAI School — Pilot Specification

## Pilot objective
Demonstrate that a learner can use OfflineAI School for curriculum-aligned study when internet access is unavailable or unreliable, while a teacher can understand learner progress when records are synchronized.

## Recommended first pilot
- 1 school
- 1 Grade 6 class or learning group
- 20–50 learners
- 1–3 teachers
- 4–8 weeks
- Start with Mathematics and Science & Technology

## Learner experience to validate
1. Create learner profile.
2. Complete baseline diagnostic.
3. Study a topic offline.
4. Complete practice offline.
5. Receive immediate explanations and adaptive recommendations.
6. Explore the density simulation.
7. Continue learning without network access.
8. Synchronize records when connectivity returns.

## Teacher experience to validate
- See practice activity derived from actual learner records.
- Identify topics needing support.
- Review evidence before progressing learners.
- Compare learner activity before and after synchronization.

## Core pilot metrics
### Access
- Percentage of sessions completed fully offline.
- Number of successful offline learning sessions.
- Sync success rate after connectivity returns.

### Engagement
- Lessons started/completed.
- Questions attempted per learner.
- Repeat practice sessions.
- Tutor questions asked.

### Learning evidence
- Diagnostic baseline.
- Practice accuracy by topic.
- Change in mastery evidence over time.
- Number of learners reaching stable mastery evidence.

### Teacher usefulness
- Teacher-reported usefulness of topic signals.
- Time required to identify learners needing support.
- Number of teacher interventions triggered by learning evidence.

## Product success criteria
The pilot should not depend on app-store scale. The minimum proof is:
- learners can complete the core learning flow offline;
- learning records persist locally;
- records synchronize without duplicate counting;
- adaptive recommendations respond to learner evidence;
- teachers see useful, non-fabricated learning signals;
- pilot teachers can explain where the product helps and where it needs improvement.

## Data principles
- Store the minimum information required for learning functionality.
- Keep core learning available without connectivity.
- Do not present diagnostic scores as practice mastery.
- Keep every attempt tied to a stable learner ID.
- Use client IDs for duplicate-safe synchronization.
- Do not expose learner data to external services unless explicitly configured and appropriately protected.

## Pilot deliverables
- Android pilot build.
- Teacher demo build or account flow.
- Pilot onboarding guide.
- 5-minute product demo.
- One-page school overview.
- Pilot feedback form.
- Before/after evidence report.
