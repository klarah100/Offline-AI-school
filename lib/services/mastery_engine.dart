import '../data/content.dart';
class MasteryEngine{
 const MasteryEngine();
 TopicMastery fromAttempts(String topicId,List<Map<String,Object?>> attempts){
  final rows=attempts.where((a)=>a['topic_id']==topicId&&a['attempt_type']=='practice').toList();
  if(rows.isEmpty)return TopicMastery(topicId:topicId,correct:0,attempted:0);
  var weightedCorrect=0.0,totalWeight=0.0;
  for(var i=0;i<rows.length;i++){final weight=1.0+(i/rows.length)*0.5;totalWeight+=weight;if(rows[i]['correct']==1)weightedCorrect+=weight;}
  return TopicMastery(topicId:topicId,correct:rows.where((r)=>r['correct']==1).length,attempted:rows.length,weightedScore:weightedCorrect/totalWeight);
 }
}