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

  test('selectQuestions respects requested count', () {
    final selected = engine.selectQuestions(
      questions,
      const TopicMastery(topicId: 'fractions', correct: 0, attempted: 0),
      3,
    );
    expect(selected.length, 3);
  });

  test('high accuracy with weak evidence does not force hard progression', () {
    final mastery = TopicMastery(
      topicId: 'fractions',
      correct: 2,
      attempted: 2,
      weightedScore: 1,
      confidence: .4,
    );
    expect(engine.nextDifficulty(mastery), 2);
    expect(engine.recommend(mastery), contains('evidence'));
  });
}
