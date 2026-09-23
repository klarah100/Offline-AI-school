import '../data/content.dart';

class AdaptiveEngine {
  const AdaptiveEngine();

  String recommend(TopicMastery mastery) {
    if (mastery.attempted == 0) {
      return 'Start with a short fractions lesson, then try five practice questions.';
    }
    if (mastery.score < .5) {
      return 'Fractions needs attention. Review the lesson and practise again.';
    }
    if (mastery.score < .8) {
      return 'You are learning fractions. Try another practice set to strengthen your understanding.';
    }
    return 'You are doing well with fractions. Move to a more challenging activity.';
  }

  int nextDifficulty(TopicMastery mastery) {
    if (mastery.score >= .8) return 3;
    if (mastery.score >= .5) return 2;
    return 1;
  }
}
