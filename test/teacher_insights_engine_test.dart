import 'package:flutter_test/flutter_test.dart';
import 'package:offline_ai_school/services/teacher_insights_engine.dart';

void main() {
  const engine = TeacherInsightsEngine();

  test('practice history creates topic support signals', () {
    final insight = engine.analyze([
      {'topic_id':'fractions','attempt_type':'practice','correct':0},
      {'topic_id':'fractions','attempt_type':'practice','correct':1},
      {'topic_id':'fractions','attempt_type':'practice','correct':0},
      {'topic_id':'matter','attempt_type':'diagnostic','correct':0},
    ]);
    expect(insight.totalAttempts, 3);
    expect(insight.activeTopics, 1);
    expect(insight.topics.single.topicId, 'fractions');
    expect(insight.topics.single.signal, 'Needs support');
  });

  test('empty history is explicit', () {
    final insight = engine.analyze([]);
    expect(insight.totalAttempts, 0);
    expect(insight.headline, 'No practice evidence yet.');
  });
}