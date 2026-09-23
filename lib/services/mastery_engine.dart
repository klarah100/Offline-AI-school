import 'dart:math' as math;
import '../data/content.dart';

class MasteryEngine {
  const MasteryEngine();

  TopicMastery fromAttempts(String topicId, List<Map<String, Object?>> attempts) {
    final rows = attempts
        .where((a) => a['topic_id'] == topicId && a['attempt_type'] == 'practice')
        .toList();
    if (rows.isEmpty) {
      return TopicMastery(topicId: topicId, correct: 0, attempted: 0);
    }

    var weightedCorrect = 0.0;
    var totalWeight = 0.0;
    for (var i = 0; i < rows.length; i++) {
      final recencyWeight = 1.0 + (i / rows.length) * 0.75;
      final difficulty = ((rows[i]['difficulty'] as int?) ?? 1).clamp(1, 3);
      final difficultyWeight = 0.85 + (difficulty - 1) * 0.10;
      final weight = recencyWeight * difficultyWeight;
      totalWeight += weight;
      if (rows[i]['correct'] == 1) weightedCorrect += weight;
    }

    final score = weightedCorrect / totalWeight;
    final recent = rows.length <= 3 ? rows : rows.sublist(rows.length - 3);
    final recentAccuracy =
        recent.where((r) => r['correct'] == 1).length / recent.length;

    final outcomes = rows
        .map((r) => r['correct'] == 1 ? 1.0 : 0.0)
        .toList();
    final consistency = rows.length <= 1
        ? 0.0
        : 1.0 - _standardDeviation(outcomes).clamp(0.0, 1.0);

    final evidence = (rows.length / 6.0).clamp(0.0, 1.0);
    final confidence = (0.45 * evidence +
            0.35 * consistency +
            0.20 * recentAccuracy)
        .clamp(0.0, 1.0);

    return TopicMastery(
      topicId: topicId,
      correct: rows.where((r) => r['correct'] == 1).length,
      attempted: rows.length,
      weightedScore: score,
      confidence: confidence,
      consistency: consistency,
    );
  }

  double _standardDeviation(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => math.pow(v - mean, 2).toDouble()).reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }
}
