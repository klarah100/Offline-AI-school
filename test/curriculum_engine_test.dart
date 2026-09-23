import 'package:flutter_test/flutter_test.dart';
import '../lib/services/curriculum_engine.dart';

void main() {
  const engine = CurriculumEngine();

  test('curriculum respects prerequisites', () {
    final initial = engine.unlocked('Grade 6', 'Mathematics', {});
    expect(initial.map((n) => n.id), contains('g6-math-fractions'));
    expect(initial.map((n) => n.id), isNot(contains('g6-math-decimals')));

    final afterFractions = engine.unlocked('Grade 6', 'Mathematics', {'g6-math-fractions'});
    expect(afterFractions.map((n) => n.id), contains('g6-math-decimals'));
    expect(afterFractions.map((n) => n.id), isNot(contains('g6-math-percentages')));
  });

  test('curriculum selects the next unmastered topic', () {
    final next = engine.nextFor('Grade 6', 'Mathematics', {'g6-math-fractions'});
    expect(next?.id, 'g6-math-decimals');
  });
}