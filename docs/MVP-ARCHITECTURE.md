# OfflineAI School — MVP Architecture

## Product goal
Prove that a learner can use OfflineAI School to learn, practice, receive personalized support, and track progress with unreliable or no internet access.

## First functional slice
- Level: Grade 6
- Subject: Mathematics
- Topic: Fractions
- Flow: onboarding → diagnostic → home → lesson → practice → feedback → recommendation → progress

## Architecture
1. **Curriculum content** — lessons, examples, questions and explanations are stored locally.
2. **Learner state** — profile, attempts and topic mastery are stored locally first.
3. **Adaptive engine** — uses recent performance to recommend the next activity.
4. **AI tutor** — provides explanations when a local/available AI capability exists; heavier cloud inference can be added later when connectivity is available.
5. **Sync layer** — queues progress changes and synchronizes them when connectivity returns.

## Data model
- users: user_id, name, grade, language, school
- subjects: subject_id, name, grade
- topics: topic_id, subject_id, name, difficulty
- lessons: lesson_id, topic_id, content, examples
- questions: question_id, topic_id, difficulty, question, answer, explanation
- attempts: user_id, question_id, answer, correct, timestamp
- mastery: user_id, topic_id, mastery_score
- sync: user_id, last_sync, pending_records

## Implementation order
1. Establish application shell and routing.
2. Build learner onboarding.
3. Build Grade 6 Mathematics/Fractions lesson.
4. Build five-question practice flow and feedback.
5. Persist learner state locally.
6. Calculate topic mastery and recommendations.
7. Add progress screen.
8. Add offline/sync queue.
9. Add AI tutor integration behind a clear interface.
10. Expand to Science and the virtual lab.

## Design source
The UI is being implemented from the OfflineAI School MVP prototype in Figma, covering 13 planned screens.

## Product principle
A student's potential should never depend on their internet connection.
