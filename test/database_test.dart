import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:offline_ai_school/services/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('creates learner and stores practice attempts separately from diagnostics', () async {
    final db = AppDatabase.instance;
    final learnerRowId = await db.saveLearner(
      name: 'Test Learner',
      grade: 'Grade 6',
      language: 'English',
      goals: ['Improve grades'],
    );
    expect(learnerRowId, greaterThan(0));

    await db.saveAttempt(
      questionId: 'q-diagnostic',
      topicId: 'fractions',
      correct: true,
      attemptType: 'diagnostic',
    );
    await db.saveAttempt(
      questionId: 'q-practice',
      topicId: 'fractions',
      correct: false,
    );

    final practice = await db.attemptsForTopic('fractions');
    expect(practice, hasLength(1));
    expect(practice.single['question_id'], 'q-practice');
    expect(practice.single['learner_id'], isNotNull);
    expect(practice.single['difficulty'], 1);

    final pending = await db.pendingAttempts();
    expect(pending, hasLength(2));
  });
}


test('links local attempts to an authenticated learner identity', () async {
  final db = AppDatabase.instance;
  await db.clearForTests();
  await db.saveLearner(name: 'Local Learner', grade: 'Grade 6', language: 'English');
  await db.saveAttempt(questionId: 'q1', topicId: 'fractions', correct: true);

  final localId = await db.learnerId();
  await db.linkLearnerId('learner_server_123456');

  expect(await db.learnerId(), 'learner_server_123456');
  final attempts = await db.attemptsForTopic('fractions', learnerId: 'learner_server_123456');
  expect(attempts, hasLength(1));
  expect(attempts.single['learner_id'], 'learner_server_123456');
  expect(localId, isNot('learner_server_123456'));
});
