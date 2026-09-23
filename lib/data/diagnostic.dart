import 'content.dart';

const diagnosticQuestions = [
  Question(id:'diagnostic-1',topicId:'fractions',prompt:'Which fraction is equal to 1/2?',options:['2/4','1/3','3/5','2/3'],answer:'2/4',explanation:'Two quarters is the same amount as one half.',difficulty:1),
  Question(id:'diagnostic-2',topicId:'fractions',prompt:'What is 2/5 + 1/5?',options:['3/5','3/10','1/5','2/10'],answer:'3/5',explanation:'With equal denominators, add the numerators.',difficulty:1),
  Question(id:'diagnostic-3',topicId:'fractions',prompt:'What is 3/7 + 2/7?',options:['5/7','5/14','1/7','6/7'],answer:'5/7',explanation:'Add 3 and 2 and keep denominator 7.',difficulty:2),
  Question(id:'diagnostic-4',topicId:'fractions',prompt:'Which is greater?',options:['3/4','1/4','1/2','2/8'],answer:'3/4',explanation:'Three quarters is greater than one half and one quarter.',difficulty:2),
  Question(id:'diagnostic-5',topicId:'fractions',prompt:'What is 4/10 in simplest form?',options:['2/5','4/5','1/10','4/20'],answer:'2/5',explanation:'Divide numerator and denominator by 2.',difficulty:2),
];