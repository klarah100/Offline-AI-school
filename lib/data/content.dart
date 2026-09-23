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

  double get score =>
      weightedScore ?? (attempted == 0 ? 0 : correct / attempted);

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
    explanation:
        'When denominators are the same, add the numerators and keep the denominator.',
    example: '3/4 + 1/4 = 4/4 = 1',
  ),
  Lesson(
    id: 'decimals-lesson-1',
    topicId: 'decimals',
    title: 'Understanding Decimals',
    objective: 'Read, compare and add decimals using place value.',
    explanation:
        'Line up decimal points so each digit keeps the correct place value.',
    example: '2.4 + 1.3 = 3.7',
  ),
  Lesson(
    id: 'percentages-lesson-1',
    topicId: 'percentages',
    title: 'Understanding Percentages',
    objective: 'Connect percentages to fractions and decimals.',
    explanation:
        'A percentage means parts per hundred. So 25% = 25/100 = 0.25.',
    example: '50% = 1/2 = 0.5',
  ),
  Lesson(
    id: 'matter-lesson-1',
    topicId: 'matter',
    title: 'States of Matter',
    objective: 'Identify solids, liquids and gases and describe their properties.',
    explanation:
        'Solids keep their shape, liquids take the shape of their container, and gases spread to fill available space.',
    example: 'Ice is a solid, water is a liquid, and water vapour is a gas.',
  ),
  Lesson(
    id: 'density-lesson-1',
    topicId: 'density',
    title: 'Density',
    objective: 'Use mass and volume to calculate density.',
    explanation:
        'Density tells us how much mass is packed into a given volume.',
    example: 'Density = mass ÷ volume = 200 g ÷ 100 cm³ = 2 g/cm³.',
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

  Question(
    id: 'decimals-q1',
    topicId: 'decimals',
    prompt: 'What is 0.4 + 0.3?',
    options: ['0.7', '0.34', '0.1', '4.3'],
    answer: '0.7',
    explanation: 'Add the tenths: 4 tenths + 3 tenths = 7 tenths.',
    difficulty: 1,
  ),
  Question(
    id: 'decimals-q2',
    topicId: 'decimals',
    prompt: 'Which is greater?',
    options: ['0.6', '0.56', '0.5', '0.06'],
    answer: '0.6',
    explanation: '0.6 is 0.60, which is greater than 0.56.',
    difficulty: 1,
  ),
  Question(
    id: 'decimals-q3',
    topicId: 'decimals',
    prompt: 'What is 2.5 + 1.2?',
    options: ['3.7', '3.3', '2.62', '4.2'],
    answer: '3.7',
    explanation: 'Line up the decimal points and add tenths and ones.',
    difficulty: 2,
  ),
  Question(
    id: 'decimals-q4',
    topicId: 'decimals',
    prompt: 'What is 5.00 - 2.35?',
    options: ['2.65', '3.35', '2.75', '3.65'],
    answer: '2.65',
    explanation: 'Subtract hundredths, tenths and ones with aligned place values.',
    difficulty: 2,
  ),
  Question(
    id: 'decimals-q5',
    topicId: 'decimals',
    prompt: 'Which decimal is equal to 3/10?',
    options: ['0.03', '0.3', '3.0', '0.13'],
    answer: '0.3',
    explanation: 'Three tenths is written as 0.3.',
    difficulty: 2,
  ),

  Question(
    id: 'percentages-q1',
    topicId: 'percentages',
    prompt: 'What does 25% mean?',
    options: ['25 out of 10', '25 out of 100', '2.5 out of 10', '1 out of 25'],
    answer: '25 out of 100',
    explanation: 'Percent means per hundred.',
    difficulty: 1,
  ),
  Question(
    id: 'percentages-q2',
    topicId: 'percentages',
    prompt: 'Which decimal is equal to 50%?',
    options: ['0.05', '0.5', '5.0', '0.15'],
    answer: '0.5',
    explanation: '50% = 50/100 = 0.5.',
    difficulty: 1,
  ),
  Question(
    id: 'percentages-q3',
    topicId: 'percentages',
    prompt: 'What fraction is equal to 25% in simplest form?',
    options: ['1/4', '1/5', '2/5', '1/2'],
    answer: '1/4',
    explanation: '25/100 simplifies to 1/4.',
    difficulty: 2,
  ),
  Question(
    id: 'percentages-q4',
    topicId: 'percentages',
    prompt: 'What is 10% of 80?',
    options: ['8', '10', '18', '800'],
    answer: '8',
    explanation: '10% is one tenth, and one tenth of 80 is 8.',
    difficulty: 2,
  ),
  Question(
    id: 'percentages-q5',
    topicId: 'percentages',
    prompt: 'What percentage is 75 out of 100?',
    options: ['7.5%', '25%', '75%', '175%'],
    answer: '75%',
    explanation: '75 parts out of 100 is 75%.',
    difficulty: 2,
  ),

  Question(
    id: 'matter-q1',
    topicId: 'matter',
    prompt: 'Which state of matter has a fixed shape?',
    options: ['Solid', 'Liquid', 'Gas', 'Plasma only'],
    answer: 'Solid',
    explanation: 'A solid keeps its own shape unless a force changes it.',
    difficulty: 1,
  ),
  Question(
    id: 'matter-q2',
    topicId: 'matter',
    prompt: 'Which state takes the shape of its container but keeps a fixed volume?',
    options: ['Solid', 'Liquid', 'Gas', 'None'],
    answer: 'Liquid',
    explanation: 'Liquids flow and take the shape of their container while keeping their volume.',
    difficulty: 1,
  ),
  Question(
    id: 'matter-q3',
    topicId: 'matter',
    prompt: 'What happens to water when it freezes?',
    options: ['It becomes a solid', 'It becomes a gas', 'It disappears', 'It becomes plasma'],
    answer: 'It becomes a solid',
    explanation: 'Freezing changes liquid water into solid ice.',
    difficulty: 2,
  ),
  Question(
    id: 'matter-q4',
    topicId: 'matter',
    prompt: 'Which particle arrangement best describes a gas?',
    options: ['Particles close and fixed', 'Particles close and sliding', 'Particles far apart and moving freely', 'No particles'],
    answer: 'Particles far apart and moving freely',
    explanation: 'Gas particles are spread out and move freely.',
    difficulty: 2,
  ),
  Question(
    id: 'matter-q5',
    topicId: 'matter',
    prompt: 'Evaporation changes a liquid into a:',
    options: ['Solid', 'Gas', 'Crystal', 'Metal'],
    answer: 'Gas',
    explanation: 'Evaporation is the change from liquid to gas at the surface.',
    difficulty: 2,
  ),

  Question(
    id: 'density-q1',
    topicId: 'density',
    prompt: 'What is the formula for density?',
    options: ['mass + volume', 'mass ÷ volume', 'volume ÷ mass', 'mass × volume'],
    answer: 'mass ÷ volume',
    explanation: 'Density = mass divided by volume.',
    difficulty: 1,
  ),
  Question(
    id: 'density-q2',
    topicId: 'density',
    prompt: 'A block has a mass of 200 g and volume of 100 cm³. What is its density?',
    options: ['0.5 g/cm³', '2 g/cm³', '20 g/cm³', '300 g/cm³'],
    answer: '2 g/cm³',
    explanation: '200 ÷ 100 = 2 g/cm³.',
    difficulty: 1,
  ),
  Question(
    id: 'density-q3',
    topicId: 'density',
    prompt: 'If mass stays constant and volume increases, density will:',
    options: ['Increase', 'Decrease', 'Stay exactly the same', 'Become zero'],
    answer: 'Decrease',
    explanation: 'With the same mass spread over a larger volume, mass per unit volume decreases.',
    difficulty: 2,
  ),
  Question(
    id: 'density-q4',
    topicId: 'density',
    prompt: 'A material has mass 300 g and volume 150 cm³. What is its density?',
    options: ['1 g/cm³', '2 g/cm³', '3 g/cm³', '450 g/cm³'],
    answer: '2 g/cm³',
    explanation: 'Density = 300 ÷ 150 = 2 g/cm³.',
    difficulty: 2,
  ),
  Question(
    id: 'density-q5',
    topicId: 'density',
    prompt: 'Which object has greater density if both have the same volume?',
    options: ['The object with less mass', 'The object with more mass', 'Both always have the same density', 'Neither'],
    answer: 'The object with more mass',
    explanation: 'For equal volumes, the object with more mass has more mass per unit volume.',
    difficulty: 2,
  ),
];
