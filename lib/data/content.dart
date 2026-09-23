class Lesson {
  final String id, topicId, title, objective, explanation, example;
  const Lesson({
    required this.id,
    required this.topicId,
    required this.title,
    required this.objective,
    required this.explanation,
    required this.example,
  });
}

class Question {
  final String id, topicId, prompt;
  final List<String> options;
  final String answer, explanation;
  final int difficulty;
  const Question({
    required this.id,
    required this.topicId,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
    required this.difficulty,
  });
}

class TopicMastery {
  final String topicId;
  final int correct, attempted;
  final double? weightedScore, confidence, consistency;

  const TopicMastery({
    required this.topicId,
    required this.correct,
    required this.attempted,
    this.weightedScore,
    this.confidence,
    this.consistency,
  });

  double get score => weightedScore ?? (attempted == 0 ? 0 : correct / attempted);

  String get label {
    if (attempted == 0) return 'Not started';
    if (attempted < 3) return 'Building evidence';
    if (score >= .85 && (confidence ?? 0) >= .7) return 'Mastered';
    if (score >= .6) return 'Learning';
    return 'Needs practice';
  }
}

const lessons = [
  Lesson(
    id: 'fractions-lesson-1',
    topicId: 'fractions',
    title: 'Adding Fractions',
    objective: 'Add fractions with the same denominator.',
    explanation: 'When denominators are the same, add the numerators and keep the denominator.',
    example: '3/4 + 1/4 = 4/4 = 1',
  ),
];

const questions = [
  Question(
    id: 'fractions-q1',
    topicId: 'fractions',
    prompt: 'What is 2/5 + 1/5?',
    options: ['1/5', '3/5', '3/10', '2/10'],
    answer: '3/5',
    explanation: 'Add the numerators and keep the denominator: 3/5.',
    difficulty: 1,
  ),
  Question(
    id: 'fractions-q2',
    topicId: 'fractions',
    prompt: 'What is 1/8 + 4/8?',
    options: ['5/8', '5/16', '3/8', '4/16'],
    answer: '5/8',
    explanation: 'Add 1 + 4 and keep denominator 8.',
    difficulty: 1,
  ),
  Question(
    id: 'fractions-q3',
    topicId: 'fractions',
    prompt: 'What is 2/7 + 3/7?',
    options: ['5/7', '5/14', '6/7', '1/7'],
    answer: '5/7',
    explanation: 'Add 2 + 3 and keep denominator 7.',
    difficulty: 2,
  ),
  Question(
    id: 'fractions-q4',
    topicId: 'fractions',
    prompt: 'What is 4/9 + 2/9?',
    options: ['6/9', '6/18', '2/9', '8/9'],
    answer: '6/9',
    explanation: 'Add 4 + 2 and keep denominator 9.',
    difficulty: 2,
  ),
  Question(
    id: 'fractions-q5',
    topicId: 'fractions',
    prompt: 'What is 3/10 + 5/10?',
    options: ['8/10', '8/20', '2/10', '15/10'],
    answer: '8/10',
    explanation: 'Add 3 + 5 and keep denominator 10.',
    difficulty: 2,
  ),
];
