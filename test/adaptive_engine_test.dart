import 'package:flutter_test/flutter_test.dart';
import 'package:offline_ai_school/data/content.dart';
import 'package:offline_ai_school/services/adaptive_engine.dart';

void main() {
  const engine = AdaptiveEngine();

  test('new topic needs practice', () {
    const mastery = TopicMastery(topicId: 'fractions', correct: 0, attempted: 0);
    expect(engine.recommend(mastery), contains('Start with'));
  });

  test('strong mastery recommends progression', () {
    const mastery = TopicMastery(topicId: 'fractions', correct: 5, attempted: 5);
    expect(engine.recommend(mastery), contains('next'));
  });
}
