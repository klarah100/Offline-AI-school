import '../data/content.dart';

class CurriculumNode {
  final String id, title, subject, level, contentTopicId;
  final List<String> prerequisites;
  final List<String> learningOutcomes;
  final double masteryThreshold;

  const CurriculumNode({
    required this.id,
    required this.title,
    required this.subject,
    required this.level,
    required this.contentTopicId,
    this.prerequisites = const [],
    this.learningOutcomes = const [],
    this.masteryThreshold = .85,
  });
}

class CurriculumEngine {
  const CurriculumEngine();

  static const nodes = <CurriculumNode>[
    CurriculumNode(
      id: 'g6-math-fractions',
      title: 'Fractions',
      subject: 'Mathematics',
      level: 'Grade 6',
      contentTopicId: 'fractions',
      learningOutcomes: ['Add fractions with the same denominator.'],
    ),
    CurriculumNode(
      id: 'g6-math-decimals',
      title: 'Decimals',
      subject: 'Mathematics',
      level: 'Grade 6',
      contentTopicId: 'decimals',
      prerequisites: ['g6-math-fractions'],
    ),
    CurriculumNode(
      id: 'g6-math-percentages',
      title: 'Percentages',
      subject: 'Mathematics',
      level: 'Grade 6',
      contentTopicId: 'percentages',
      prerequisites: ['g6-math-fractions', 'g6-math-decimals'],
    ),
    CurriculumNode(
      id: 'g6-science-matter',
      title: 'Matter',
      subject: 'Science and Technology',
      level: 'Grade 6',
      contentTopicId: 'matter',
    ),
    CurriculumNode(
      id: 'g6-science-density',
      title: 'Density',
      subject: 'Science and Technology',
      level: 'Grade 6',
      contentTopicId: 'density',
      prerequisites: ['g6-science-matter'],
    ),
  ];

  List<CurriculumNode> pathFor(String level, String subject) =>
      nodes.where((n) => n.level == level && n.subject == subject).toList();

  List<CurriculumNode> unlocked(
    String level,
    String subject,
    Set<String> mastered,
  ) =>
      pathFor(level, subject)
          .where((n) => n.prerequisites.every(mastered.contains))
          .toList();

  CurriculumNode? nextFor(
    String level,
    String subject,
    Set<String> mastered,
  ) {
    for (final node in pathFor(level, subject)) {
      if (!mastered.contains(node.id) &&
          node.prerequisites.every(mastered.contains)) {
        return node;
      }
    }
    return null;
  }

  List<Question> questionsFor(
    String contentTopicId,
    List<Question> pool,
  ) =>
      pool.where((q) => q.topicId == contentTopicId).toList();
}
