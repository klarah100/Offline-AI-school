import 'package:flutter/material.dart';
import 'data/content.dart';
import 'data/diagnostic.dart';
import 'services/adaptive_engine.dart';
import 'services/ai_tutor.dart';
import 'services/connectivity_service.dart';
import 'services/database.dart';
import 'services/sync_service.dart';
import 'services/mastery_engine.dart';
import 'services/teacher_insights_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OfflineAISchoolApp());
}

class AppState extends ChangeNotifier {
  AppState(this.db);
  final AppDatabase db;
  final AdaptiveEngine adaptive = const AdaptiveEngine();
  final MasteryEngine masteryEngine = const MasteryEngine();
  final AiTutor tutor = const OfflineAiTutor();
  String learnerName = 'Learner';
  String grade = 'Grade 6';
  String language = 'English';
  List<String> goals = [];
  final Map<String, TopicMastery> masteries = {};
  TopicMastery get mastery => masteryFor('fractions');
  TopicMastery masteryFor(String topicId) =>
      masteries[topicId] ?? TopicMastery(topicId: topicId, correct: 0, attempted: 0);
  bool loading = true;

  Future<void> load() async {
    final row = await db.learner();
    if (row != null) {
      learnerName = row['name'] as String? ?? 'Learner';
      grade = row['grade'] as String? ?? 'Grade 6';
      language = row['language'] as String? ?? 'English';
      final raw = row['goals'] as String? ?? '';
      goals = raw.isEmpty ? [] : raw.split('|');
    }
    await refreshMastery();
    loading = false;
    notifyListeners();
  }

  Future<void> saveProfile(
    String name,
    String selectedGrade,
    String selectedLanguage,
    List<String> selectedGoals,
  ) async {
    learnerName = name.trim().isEmpty ? 'Learner' : name.trim();
    grade = selectedGrade;
    language = selectedLanguage;
    goals = selectedGoals;
    await db.saveLearner(
      name: learnerName,
      grade: grade,
      language: language,
      goals: goals,
    );
    notifyListeners();
  }

  Future<void> refreshMastery([String? topicId]) async {
    final learnerId = await db.learnerId();
    final ids = topicId == null
        ? const ['fractions', 'decimals', 'percentages', 'matter', 'density']
        : [topicId];
    for (final id in ids) {
      final rows = await db.attemptsForTopic(id, learnerId: learnerId);
      masteries[id] = masteryEngine.fromAttempts(id, rows);
    }
  }

  Future<void> record(
    Question q,
    String answer, {
    String attemptType = 'practice',
    int? durationMs,
  }) async {
    await db.saveAttempt(
      questionId: q.id,
      topicId: q.topicId,
      correct: answer == q.answer,
      attemptType: attemptType,
      selectedAnswer: answer,
      durationMs: durationMs,
      difficulty: q.difficulty,
    );
    await refreshMastery(q.topicId);
    notifyListeners();
  }
}
class OfflineAISchoolApp extends StatefulWidget {
  const OfflineAISchoolApp({super.key});
  @override State<OfflineAISchoolApp> createState() => _OfflineAISchoolAppState();
}

class _OfflineAISchoolAppState extends State<OfflineAISchoolApp> {
  final state = AppState(AppDatabase.instance);
  @override void initState() { super.initState(); state.load(); }
  @override void dispose() { state.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (_, __) => MaterialApp(
      title: 'OfflineAI School',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      home: state.loading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : state.learnerName == 'Learner'
          ? ProfileScreen(state: state, firstRun: true)
          : HomeScreen(state: state),
    ),
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.state, this.firstRun = false});
  final AppState state; final bool firstRun;
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController name;
  String grade = 'Grade 6', language = 'English';
  final goals = <String>{};

  @override void initState() {
    super.initState();
    name = TextEditingController(text: widget.state.learnerName == 'Learner' ? '' : widget.state.learnerName);
    grade = widget.state.grade; language = widget.state.language; goals.addAll(widget.state.goals);
  }
  @override void dispose() { name.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    const options = ['Improve my grades','Understand difficult topics','Prepare for exams','Explore science','Practise regularly'];
    return Scaffold(
      appBar: widget.firstRun ? null : AppBar(title: const Text('Learner Profile')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 12),
        Text(widget.firstRun ? 'Let’s personalize your learning' : 'Learner Profile',
          style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Your choices stay on this device and shape your learning path.'),
        const SizedBox(height: 24),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: grade, decoration: const InputDecoration(labelText: 'Level'),
          items: const ['Grade 6','Form 1'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
          onChanged:(v)=>setState(()=>grade=v??grade)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: language, decoration: const InputDecoration(labelText: 'Preferred language'),
          items: const ['English'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
          onChanged:(v)=>setState(()=>language=v??language)),
        const SizedBox(height: 22),
        const Text('Learning goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ...options.map((g)=>CheckboxListTile(
          value: goals.contains(g), title: Text(g), contentPadding: EdgeInsets.zero,
          onChanged:(v)=>setState(()=>v==true?goals.add(g):goals.remove(g)))),
        const SizedBox(height: 12),
        FilledButton(
          onPressed:() async {
            await widget.state.saveProfile(name.text, grade, language, goals.toList());
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>DiagnosticScreen(state:widget.state)),(_)=>false);
          },
          child: const Padding(padding: EdgeInsets.all(13),child:Text('Continue'))),
      ]),
    );
  }
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key, required this.state});
  final AppState state;
  @override State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}
class _DiagnosticScreenState extends State<DiagnosticScreen> {
  int index = 0, correct = 0; String? selected;
  Question get q => diagnosticQuestions[index];
  Future<void> submit() async {
    if (selected == null) return;
    if (selected == q.answer) correct++;
    await widget.state.record(q, selected!, attemptType: 'diagnostic');
    if (!mounted) return;
    if (index == diagnosticQuestions.length - 1) {
      await widget.state.refreshMastery();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DiagnosticResultScreen(state: widget.state, correct: correct)));
    } else { setState(() { index++; selected = null; }); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Diagnostic ${index + 1}/${diagnosticQuestions.length}')),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      const Text('Let’s find your starting point', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('This short assessment helps OfflineAI School personalize your first learning path.'),
      const SizedBox(height: 22),
      LinearProgressIndicator(value: (index + 1) / diagnosticQuestions.length),
      const SizedBox(height: 28),
      Text(q.prompt, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      ...q.options.map((o) => Padding(padding: const EdgeInsets.only(bottom: 10), child: OutlinedButton(
        onPressed: () => setState(() => selected = o),
        style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(18)),
        child: Text(o)))),
      FilledButton(onPressed: selected == null ? null : submit, child: Text(index == diagnosticQuestions.length - 1 ? 'Finish diagnostic' : 'Next')),
    ]));
}
class DiagnosticResultScreen extends StatelessWidget {
  const DiagnosticResultScreen({super.key, required this.state, required this.correct});
  final AppState state; final int correct;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your starting point')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      const Icon(Icons.auto_awesome_rounded, size: 64), const SizedBox(height: 16),
      Text('${correct}/${diagnosticQuestions.length} diagnostic questions correct', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      const Text('We’ll use this baseline to recommend what to practise next.', textAlign: TextAlign.center),
      const SizedBox(height: 24),
      FilledButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomeScreen(state: state)), (_) => false), child: const Text('Start learning')),
    ]));
}
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state}); final AppState state;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('OfflineAI School'), actions:[
      IconButton(icon:const Icon(Icons.sync_rounded),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SyncScreen(state:state))))
    ]),
    body: ListView(padding:const EdgeInsets.all(20),children:[
      Text('Good afternoon, ${state.learnerName} 👋',style:const TextStyle(fontSize:27,fontWeight:FontWeight.w800)),
      const SizedBox(height:6), const Text('Keep building your understanding, one concept at a time.'),
      const SizedBox(height:20),
      _Card(title:'Continue Learning',subtitle:'Mathematics • Fractions • ${state.mastery.label}',progress:state.mastery.score,
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(state:state,topicId:'fractions')))),
      const SizedBox(height:18),
      _Tool(title:'Mathematics',subtitle:'Fractions • Decimals • Percentages',icon:Icons.calculate_rounded,
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MathTopicsScreen(state:state)))),
      _Tool(title:'Ask OfflineAI',subtitle:'Get an explanation without internet',icon:Icons.psychology_rounded,
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>TutorScreen(state:state)))),
      _Tool(title:'Virtual Science Lab',subtitle:'Experiment with density',icon:Icons.science_rounded,
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const LabScreen()))),
      _Tool(title:'My Progress',subtitle:'Mastery and next recommendation',icon:Icons.insights_rounded,
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProgressScreen(state:state)))),
      _Tool(title:'Teacher Dashboard',subtitle:'Real learner learning signals',icon:Icons.school_rounded,
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>TeacherScreen(state:state)))),
    ]),
  );
}

class MathTopicsScreen extends StatelessWidget {
  const MathTopicsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    const topicIds = ['fractions', 'decimals', 'percentages'];
    return Scaffold(
      appBar: AppBar(title: const Text('Grade 6 Mathematics')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text('Choose a topic', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Your learning path will adapt as OfflineAI sees more evidence of your understanding.'),
          const SizedBox(height: 18),
          ...topicIds.map((topicId) {
            final lesson = lessons.firstWhere((item) => item.topicId == topicId);
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(child: Icon(Icons.calculate_rounded)),
                title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(lesson.objective + ' • ' + state.masteryFor(topicId).label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => LessonScreen(state: state, topicId: topicId),
                )),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.state, required this.topicId});
  final AppState state;
  final String topicId;

  @override
  Widget build(BuildContext context) {
    final lesson = lessons.firstWhere((item) => item.topicId == topicId);
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(lesson.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(lesson.objective),
          const SizedBox(height: 20),
          _Info(title: 'Understand', body: lesson.explanation, icon: Icons.lightbulb_rounded),
          const SizedBox(height: 12),
          _Info(title: 'Example', body: lesson.example, icon: Icons.functions_rounded),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PracticeScreen(state: state, topicId: topicId),
            )),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start 5-question practice'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TutorScreen(state: state, topicId: topicId))),
            icon: const Icon(Icons.psychology_rounded),
            label: const Text('Ask OfflineAI'),
          ),
        ],
      ),
    );
  }
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.state, required this.topicId});
  final AppState state;
  final String topicId;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int index = 0;
  int correct = 0;
  String? selected;
  bool checked = false;
  DateTime questionStarted = DateTime.now();

  List<Question> get topicQuestions => questions.where((q) => q.topicId == widget.topicId).toList();
  Question get q => topicQuestions[index];

  Future<void> check() async {
    if (selected == null || checked) return;
    if (selected == q.answer) correct++;
    final durationMs = DateTime.now().difference(questionStarted).inMilliseconds;
    await widget.state.record(q, selected!, durationMs: durationMs);
    setState(() => checked = true);
  }

  void next() {
    if (index == topicQuestions.length - 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(
        state: widget.state, correct: correct, total: topicQuestions.length, topicId: widget.topicId,
      )));
    } else {
      setState(() { index++; selected = null; checked = false; questionStarted = DateTime.now(); });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Practice ' + (index + 1).toString() + '/' + topicQuestions.length.toString())),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        LinearProgressIndicator(value: (index + 1) / topicQuestions.length),
        const SizedBox(height: 28),
        Text(q.prompt, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        ...q.options.map((option) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton(
            onPressed: checked ? null : () => setState(() => selected = option),
            style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(18)),
            child: Text(option),
          ),
        )),
        if (checked) _Feedback(correct: selected == q.answer, text: q.explanation),
        FilledButton(
          onPressed: selected == null ? null : (checked ? next : check),
          child: Text(checked ? (index == topicQuestions.length - 1 ? 'See results' : 'Next question') : 'Check answer'),
        ),
      ],
    ),
  );
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.state, required this.correct, required this.total, required this.topicId});
  final AppState state;
  final int correct;
  final int total;
  final String topicId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Practice complete')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.celebration_rounded, size: 64),
        const SizedBox(height: 12),
        Text(correct.toString() + '/' + total.toString() + ' correct', textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(state.adaptive.recommend(state.mastery), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProgressScreen(state: state))),
          child: const Text('View progress'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          child: const Text('Back to home'),
        ),
      ],
    ),
  );
}
class TutorScreen extends StatefulWidget{const TutorScreen({super.key,required this.state,this.topicId});final AppState state;final String? topicId;@override State<TutorScreen>createState()=>_TutorScreenState();}
class _TutorScreenState extends State<TutorScreen>{final c=TextEditingController(text:'Explain fractions to me');String answer='';
@override void dispose(){c.dispose();super.dispose();}
Future<void> ask()async{final a=await widget.state.tutor.explain(c.text,topicId:widget.topicId);if(mounted)setState(()=>answer=a);}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Ask OfflineAI')),body:ListView(padding:const EdgeInsets.all(22),children:[
const _Pill(text:'Offline tutor mode'),const SizedBox(height:18),const Text('Ask a question',style:TextStyle(fontSize:29,fontWeight:FontWeight.w800)),
const SizedBox(height:8),const Text('This MVP tutor answers from locally stored learning knowledge.'),const SizedBox(height:18),
TextField(controller:c,maxLines:4,decoration:const InputDecoration(hintText:'e.g. Why do we keep the denominator?')),
const SizedBox(height:12),FilledButton.icon(onPressed:ask,icon:const Icon(Icons.send_rounded),label:const Text('Ask')),
if(answer.isNotEmpty)...[const SizedBox(height:18),_Info(title:'OfflineAI explains',body:answer,icon:Icons.psychology_rounded)]
]));}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    const topics = ['fractions', 'decimals', 'percentages', 'matter', 'density'];
    const names = {'fractions':'Fractions','decimals':'Decimals','percentages':'Percentages','matter':'Matter','density':'Density'};
    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text('Your progress', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          ...topics.map((topicId) {
            final mastery = state.masteryFor(topicId);
            final value = mastery.attempted == 0 ? mastery.label : (mastery.score * 100).round().toString() + '%';
            return _Metric(label: names[topicId]!, value: value, icon: topicId == 'matter' || topicId == 'density' ? Icons.science_rounded : Icons.track_changes_rounded);
          }),
          const SizedBox(height: 12),
          _Info(title:'Fractions recommendation', body:state.adaptive.recommend(state.masteryFor('fractions')), icon:Icons.auto_awesome_rounded),
          _Info(title:'Science recommendation', body:state.adaptive.recommend(state.masteryFor('density')), icon:Icons.science_rounded),
        ],
      ),
    );
  }
}
class ScienceTopicsScreen extends StatelessWidget {
  const ScienceTopicsScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    const topicIds = ['matter', 'density'];
    return Scaffold(
      appBar: AppBar(title: const Text('Grade 6 Science & Technology')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text('Explore and experiment', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Learn the concept first, then test your understanding and experiment in the virtual lab.'),
          const SizedBox(height: 18),
          ...topicIds.map((topicId) {
            final lesson = lessons.firstWhere((item) => item.topicId == topicId);
            final mastery = state.masteryFor(topicId);
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(child: Icon(Icons.science_rounded)),
                title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(lesson.objective + ' • ' + mastery.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => LessonScreen(state: state, topicId: topicId),
                )),
              ),
            );
          }),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.science)),
              title: const Text('Virtual Density Lab', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Change mass and volume and observe density.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
class LabScreen extends StatefulWidget{const LabScreen({super.key});@override State<LabScreen>createState()=>_LabScreenState();}
class _LabScreenState extends State<LabScreen>{double mass=200,volume=100;
@override Widget build(BuildContext context){final density=mass/volume;return Scaffold(appBar:AppBar(title:const Text('Virtual Science Lab')),body:ListView(padding:const EdgeInsets.all(22),children:[
const Text('Density experiment',style:TextStyle(fontSize:29,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Change mass and volume and observe the result.'),
const SizedBox(height:20),Text('Mass: ${mass.round()} g'),Slider(value:mass,min:50,max:500,divisions:45,onChanged:(v)=>setState(()=>mass=v)),
Text('Volume: ${volume.round()} cm³'),Slider(value:volume,min:50,max:500,divisions:45,onChanged:(v)=>setState(()=>volume=v)),
_Info(title:'Calculated density',body:'${density.toStringAsFixed(2)} g/cm³\nDensity = mass ÷ volume',icon:Icons.science_rounded),
const SizedBox(height:18),const Text('Prediction: if mass stays constant and volume increases, what happens to density?')
]));}}

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key, required this.state});
  final AppState state;
  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final engine = const TeacherInsightsEngine();
  TeacherInsights? insights;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final learnerId = await widget.state.db.learnerId();
    final attempts = await widget.state.db.practiceAttemptsForLearner(learnerId);
    if (mounted) setState(() => insights = engine.analyze(attempts));
  }

  @override
  Widget build(BuildContext context) {
    final data = insights;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Teacher Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text('Learning signals', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Pilot view for ' + widget.state.learnerName + '. Synchronized class aggregation will extend this layer for schools.'),
          const SizedBox(height: 18),
          _Metric(label: 'Practice attempts', value: data.totalAttempts.toString(), icon: Icons.quiz_rounded),
          _Metric(label: 'Active topics', value: data.activeTopics.toString(), icon: Icons.menu_book_rounded),
          _Metric(label: 'Topics needing support', value: data.topicsNeedingSupport.toString(), icon: Icons.priority_high_rounded),
          const SizedBox(height: 12),
          _Info(title: 'AI-assisted insight', body: data.headline, icon: Icons.insights_rounded),
          const SizedBox(height: 12),
          ...data.topics.map((topic) => Card(
            child: ListTile(
              title: Text(topic.topicId, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(topic.signal + ' • ' + topic.attempted.toString() + ' attempts'),
              trailing: Text((topic.accuracy * 100).round().toString() + '%'),
            ),
          )),
        ],
      ),
    );
  }
}
class SyncScreen extends StatefulWidget{const SyncScreen({super.key,required this.state});final AppState state;@override State<SyncScreen>createState()=>_SyncScreenState();}
class _SyncScreenState extends State<SyncScreen>{final connectivity=ConnectivityService();int pending=0;bool online=false,busy=false;String message='Ready';
@override void initState(){super.initState();refresh();}
Future<void> refresh()async{online=await connectivity.isOnline();pending=await widget.state.db.pendingCount();if(mounted)setState((){});}
Future<void> sync()async{setState(()=>busy=true);try{final n=await SyncService(database:widget.state.db,connectivity:connectivity).syncPending();message=n==0?'Nothing synchronized.':'${n} records synchronized.';}catch(_){message='Sync failed; your learning data remains on this device.';}await refresh();if(mounted)setState(()=>busy=false);}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Offline & Sync')),body:ListView(padding:const EdgeInsets.all(22),children:[
_Info(title:online?'Connection detected':'Offline mode',body:online?'A network is available.':'Core learning remains available without internet.',icon:online?Icons.wifi_rounded:Icons.cloud_off_rounded),
_Metric(label:'Pending records',value:'${pending}',icon:Icons.sync_rounded),const SizedBox(height:12),
FilledButton.icon(onPressed:busy?null:sync,icon:const Icon(Icons.sync_rounded),label:Text(busy?'Synchronizing...':'Sync now')),const SizedBox(height:10),
Text(message,textAlign:TextAlign.center),const SizedBox(height:18),
const Text('Records are marked synced only after the transport layer succeeds.',style:TextStyle(color:Color(0xFF64748B)))
]));}

class _Card extends StatelessWidget{const _Card({required this.title,required this.subtitle,required this.progress,required this.onTap});final String title,subtitle;final double progress;final VoidCallback onTap;
@override Widget build(BuildContext context)=>Card(child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(16),child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(subtitle),const SizedBox(height:14),LinearProgressIndicator(value:progress)]))));}
class _Tool extends StatelessWidget{const _Tool({required this.title,required this.subtitle,required this.icon,required this.onTap});final String title,subtitle;final IconData icon;final VoidCallback onTap;
@override Widget build(BuildContext context)=>Card(child:ListTile(onTap:onTap,leading:CircleAvatar(child:Icon(icon)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right_rounded)));}
class _Info extends StatelessWidget{const _Info({required this.title,required this.body,required this.icon});final String title,body;final IconData icon;
@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[CircleAvatar(child:Icon(icon)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),Text(body,style:const TextStyle(height:1.4))]))])));}
class _Metric extends StatelessWidget{const _Metric({required this.label,required this.value,required this.icon});final String label,value;final IconData icon;
@override Widget build(BuildContext context)=>Card(child:ListTile(leading:CircleAvatar(child:Icon(icon)),title:Text(label),trailing:Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800))));}
class _Feedback extends StatelessWidget{const _Feedback({required this.correct,required this.text});final bool correct;final String text;
@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(correct?'Correct ✓':'Not quite yet',style:TextStyle(fontWeight:FontWeight.w800,color:correct?Colors.green.shade700:Colors.red.shade700)),const SizedBox(height:8),Text(text)])));}
class _Pill extends StatelessWidget{const _Pill({required this.text});final String text;
@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:const Color(0xFFEFF6FF),borderRadius:BorderRadius.circular(14)),child:Row(children:[const Icon(Icons.cloud_off_rounded,color:Color(0xFF2563EB)),const SizedBox(width:10),Expanded(child:Text(text,style:const TextStyle(fontWeight:FontWeight.w700)))]));}
