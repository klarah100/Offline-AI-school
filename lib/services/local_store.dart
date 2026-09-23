import '../data/content.dart';

class Attempt {
  final String questionId;
  final bool correct;
  final DateTime timestamp;

  const Attempt({
    required this.questionId,
    required this.correct,
    required this.timestamp,
  });
}

class LocalStore {
  final List<Attempt> _attempts = [];

  List<Attempt> get attempts => List.unmodifiable(_attempts);

  void recordAttempt({
    required String questionId,
    required bool correct,
  }) {
    _attempts.add(
      Attempt(
        questionId: questionId,
        correct: correct,
        timestamp: DateTime.now(),
      ),
    );
  }

  TopicMastery masteryFor(String topicId) {
    final topicQuestionIds = questions
        .where((question) => question.topicId == topicId)
        .map((question) => question.id)
        .toSet();

    final relevant = _attempts.where(
      (attempt) => topicQuestionIds.contains(attempt.questionId),
    );

    final list = relevant.toList();
    return TopicMastery(
      topicId: topicId,
      correct: list.where((attempt) => attempt.correct).length,
      attempted: list.length,
    );
  }

  bool get hasPendingSync => _attempts.isNotEmpty;

  void markSynced() {
    // Phase 3 will replace this in-memory placeholder with a persistent
    // local database and a durable sync queue.
  }
}
