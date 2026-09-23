import '../data/content.dart';
class CurriculumNode{final String id,title,subject,level;final List<String> prerequisites;const CurriculumNode({required this.id,required this.title,required this.subject,required this.level,this.prerequisites=const[]});}
class CurriculumEngine{
 const CurriculumEngine();
 static const nodes=<CurriculumNode>[CurriculumNode(id:'g6-math-fractions',title:'Fractions',subject:'Mathematics',level:'Grade 6'),CurriculumNode(id:'g6-math-decimals',title:'Decimals',subject:'Mathematics',level:'Grade 6',prerequisites:['g6-math-fractions']),CurriculumNode(id:'g6-math-percentages',title:'Percentages',subject:'Mathematics',level:'Grade 6',prerequisites:['g6-math-fractions','g6-math-decimals']),CurriculumNode(id:'g6-science-matter',title:'Matter',subject:'Science and Technology',level:'Grade 6'),CurriculumNode(id:'g6-science-density',title:'Density',subject:'Science and Technology',level:'Grade 6',prerequisites:['g6-science-matter'])];
 List<CurriculumNode> pathFor(String level,String subject)=>nodes.where((n)=>n.level==level&&n.subject==subject).toList();
 List<CurriculumNode> unlocked(String level,String subject,Set<String> mastered)=>pathFor(level,subject).where((n)=>n.prerequisites.every(mastered.contains)).toList();
 CurriculumNode? nextFor(String level,String subject,Set<String> mastered){for(final n in unlocked(level,subject,mastered)){if(!mastered.contains(n.id))return n;}return null;}
 List<Question> questionsFor(String topicId,List<Question> pool)=>pool.where((q)=>q.topicId==topicId).toList();
}