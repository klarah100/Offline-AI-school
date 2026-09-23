import '../data/content.dart';

class AdaptiveEngine {
  const AdaptiveEngine();

  String recommend(TopicMastery mastery) {
    if (mastery.attempted == 0) {
      return 'Start with a short lesson, then try five practice questions.';
    }
    if (mastery.attempted < 3) {
      return 'Keep practising so OfflineAI can build more evidence of your understanding.';
    }
    if (mastery.score < .4) {
      return 'Review the concept with a worked example, then retry an easier practice set.';
    }
    if (mastery.score < .7) {
      return 'Practise the same skill again with mixed difficulty and immediate feedback.';
    }
    if (mastery.score < .85 || (mastery.confidence ?? 1) < .7) {
      return 'You are making progress. Complete a mixed set to confirm the skill is stable.';
    }
    return 'You are doing well. Move to the next, more challenging activity.';
  }

  int nextDifficulty(TopicMastery mastery) {
    if (mastery.score >= .85 && (mastery.confidence ?? 1) >= .7) return 3;
    if (mastery.score >= .7) return 2;
    return 1;
  }

  List<Question> selectQuestions(
    List<Question> pool,
    TopicMastery mastery,
    int count,
  ) {
    if (count <= 0 || pool.isEmpty) return const [];
    final target = nextDifficulty(mastery);
    final sorted = [...pool]
      ..sort((a, b) =>
          (a.difficulty - target).abs().compareTo((b.difficulty - target).abs()));
    return sorted.take(count.clamp(0, sorted.length)).toList();
  }
}
