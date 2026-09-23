class Lesson {
  final String id;
  final String topicId;
  final String title;
  final String objective;
  final String explanation;
  final String example;

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
  final String id;
  final String topicId;
  final String prompt;
  final List<String> options;
  final String answer;
  final String explanation;
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
    explanation: 'The denominators are the same, so add 2 + 1 and keep 5: 3/5.',
    difficulty: 1,
  ),
  Question(
    id: 'fractions-q2',
    topicId: 'fractions',
    prompt: 'What is 1/8 + 4/8?',
    options: ['5/8', '5/16', '3/8', '4/16'],
    answer: '5/8',
    explanation: 'Add the numerators: 1 + 4 = 5, while the denominator stays 8.',
    difficulty: 1,
  ),
  Question(
    id: 'fractions-q3',
    topicId: 'fractions',
    prompt: 'What is 2/7 + 3/7?',
    options: ['5/7', '5/14', '6/7', '1/7'],
    answer: '5/7',
    explanation: 'Add 2 + 3 = 5 and keep the denominator 7.',
    difficulty: 2,
  ),
  Question(
    id: 'fractions-q4',
    topicId: 'fractions',
    prompt: 'What is 4/9 + 2/9?',
    options: ['6/9', '6/18', '2/9', '8/9'],
    answer: '6/9',
    explanation: 'Add the numerators 4 + 2 = 6 and keep denominator 9.',
    difficulty: 2,
  ),
  Question(
    id: 'fractions-q5',
    topicId: 'fractions',
    prompt: 'What is 3/10 + 5/10?',
    options: ['8/10', '8/20', '2/10', '15/10'],
    answer: '8/10',
    explanation: 'Add the numerators: 3 + 5 = 8. The denominator remains 10.',
    difficulty: 2,
  ),
];

class TopicMastery {
  final String topicId;
  final int correct;
  final int attempted;

  const TopicMastery({
    required this.topicId,
    required this.correct,
    required this.attempted,
  });

  double get score => attempted == 0 ? 0 : correct / attempted;

  String get label {
    if (score >= .8) return 'Mastered';
    if (score >= .5) return 'Learning';
    return 'Needs practice';
  }
}
