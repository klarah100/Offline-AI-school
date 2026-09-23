import '../data/content.dart';
class AdaptiveEngine {
 const AdaptiveEngine();
 String recommend(TopicMastery mastery){if(mastery.attempted==0)return 'Start with a short lesson, then try five practice questions.';if(mastery.score<.4)return 'Review the concept with a worked example, then retry an easier practice set.';if(mastery.score<.7)return 'Practise the same skill again with mixed difficulty and immediate feedback.';if(mastery.score<.85)return 'You are making progress. Try a mixed set to check whether the skill is stable.';return 'You are doing well. Move to the next, more challenging activity.';}
 int nextDifficulty(TopicMastery mastery)=>mastery.score>=.85?3:mastery.score>=.7?2:1;
 List<Question> selectQuestions(List<Question> pool,TopicMastery mastery,int count){if(count<=0||pool.isEmpty)return const[];final target=nextDifficulty(mastery);final sorted=[...pool]..sort((a,b)=>(a.difficulty-target).abs().compareTo((b.difficulty-target).abs()));return sorted.take(count.clamp(0,sorted.length)).toList();}
}