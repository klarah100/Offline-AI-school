import 'package:flutter_test/flutter_test.dart';
import 'package:offline_ai_school/data/diagnostic.dart';

void main() {
  test('diagnostic is five-question fractions assessment', () {
    expect(diagnosticQuestions, hasLength(5));
    expect(diagnosticQuestions.every((q) => q.topicId == 'fractions'), isTrue);
    expect(diagnosticQuestions.every((q) => q.options.contains(q.answer)), isTrue);
  });

  test('diagnostic answers are internally consistent', () {
    expect(diagnosticQuestions[0].answer, '2/4');
    expect(diagnosticQuestions[1].answer, '3/5');
    expect(diagnosticQuestions[2].answer, '5/7');
    expect(diagnosticQuestions[3].answer, '3/4');
    expect(diagnosticQuestions[4].answer, '2/5');
  });
}
