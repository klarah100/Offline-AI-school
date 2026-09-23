import 'package:flutter_test/flutter_test.dart';
import 'package:offline_ai_school/services/ai_tutor.dart';

void main() {
  const tutor = OfflineAiTutor();

  test('explains fractions from offline curriculum knowledge', () async {
    final answer = await tutor.explain('Why do we keep the denominator?', topicId: 'fractions');
    expect(answer, contains('denominator'));
    expect(answer, contains('2/5 + 1/5'));
  });

  test('explains density with a formula', () async {
    final answer = await tutor.explain('What is density?', topicId: 'density');
    expect(answer, contains('mass ÷ volume'));
  });

  test('guards empty prompts', () async {
    final answer = await tutor.explain('');
    expect(answer, contains('school-learning question'));
  });
}