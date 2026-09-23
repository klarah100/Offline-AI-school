import '../data/content.dart';

class TopicInsight {
  final String topicId;
  final int attempted;
  final int correct;
  final double accuracy;
  final String signal;

  const TopicInsight({
    required this.topicId,
    required this.attempted,
    required this.correct,
    required this.accuracy,
    required this.signal,
  });
}

class TeacherInsights {
  final int totalAttempts;
  final int activeTopics;
  final int topicsNeedingSupport;
  final List<TopicInsight> topics;

  const TeacherInsights({
    required this.totalAttempts,
    required this.activeTopics,
    required this.topicsNeedingSupport,
    required this.topics,
  });

  String get headline {
    if (totalAttempts == 0) return 'No practice evidence yet.';
    if (topicsNeedingSupport == 0) return 'Current evidence shows steady progress across practised topics.';
    return 'Some practised topics need targeted support before progression.';
  }
}

class TeacherInsightsEngine {
  const TeacherInsightsEngine();

  TeacherInsights analyze(List<Map<String, Object?>> attempts) {
    final practice = attempts.where((a) => a['attempt_type'] == 'practice').toList();
    final ids = <String>{
      ...practice.map((a) => a['topic_id']).whereType<String>(),
    };
    final topics = <TopicInsight>[];

    for (final topicId in ids) {
      final rows = practice.where((a) => a['topic_id'] == topicId).toList();
      final correct = rows.where((a) => a['correct'] == 1).length;
      final accuracy = correct / rows.length;
      final signal = rows.length < 3
          ? 'More evidence needed'
          : accuracy < .6
              ? 'Needs support'
              : accuracy < .85
                  ? 'Developing'
                  : 'Strong';
      topics.add(TopicInsight(
        topicId: topicId,
        attempted: rows.length,
        correct: correct,
        accuracy: accuracy,
        signal: signal,
      ));
    }

    topics.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return TeacherInsights(
      totalAttempts: practice.length,
      activeTopics: topics.length,
      topicsNeedingSupport: topics.where((t) => t.signal == 'Needs support').length,
      topics: topics,
    );
  }
}