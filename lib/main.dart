import 'package:flutter/material.dart';
import 'services/database.dart';
import 'services/adaptive_engine.dart';
import 'services/ai_tutor.dart';
import 'data/content.dart';

final appDatabase = AppDatabase.instance;
final adaptiveEngine = const AdaptiveEngine();
final aiTutor = const OfflineAiTutor();
TopicMastery currentMastery = const TopicMastery(topicId: 'fractions', correct: 0, attempted: 0);

void main() {
  runApp(const OfflineAISchoolApp());
}

class OfflineAISchoolApp extends StatelessWidget {
  const OfflineAISchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfflineAI School',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 28),
              const Text(
                'OFFLINEAI SCHOOL',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.6),
              ),
              const SizedBox(height: 16),
              const Text(
                'Learn anywhere.\nEven offline.',
                style: TextStyle(fontSize: 40, height: 1.08, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Text(
                'Personalized learning powered by AI, designed for students who cannot depend on continuous internet access.',
                style: TextStyle(fontSize: 17, height: 1.45, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 20, color: Color(0xFF2563EB)),
                    SizedBox(width: 10),
                    Text('Works without internet', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Start Learning', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your potential should never depend on your internet connection.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  String level = 'Grade 6';
  String language = 'English';
  final goals = <String>{};

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const goalOptions = [
      'Improve my grades',
      'Understand difficult topics',
      'Prepare for exams',
      'Explore science',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Learner Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Tell us about yourself', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('We use this to personalize your learning path.'),
          const SizedBox(height: 28),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: level,
            decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
            items: ['Grade 6', 'Form 1'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => level = v ?? level),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: language,
            decoration: const InputDecoration(labelText: 'Preferred language', border: OutlineInputBorder()),
            items: ['English'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => language = v ?? language),
          ),
          const SizedBox(height: 26),
          const Text('What do you want to achieve?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...goalOptions.map((goal) => CheckboxListTile(
                value: goals.contains(goal),
                title: Text(goal),
                contentPadding: EdgeInsets.zero,
                onChanged: (checked) => setState(() => checked == true ? goals.add(goal) : goals.remove(goal)),
              )),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              await appDatabase.saveLearner(name: nameController.text.trim().isEmpty ? 'Learner' : nameController.text.trim(), grade: level, language: language);
              if (!context.mounted) return;
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OfflineAI School'),
        actions: const [Padding(padding: EdgeInsets.only(right: 18), child: Icon(Icons.cloud_off_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Good afternoon, learner 👋', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Ready to keep learning?'),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Continue Learning',
            subtitle: 'Mathematics • Fractions • ' + currentMastery.label,
            progress: currentMastery.score,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FractionsScreen())),
          ),
          const SizedBox(height: 14),
          const Text('Your subjects', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _SubjectCard(icon: Icons.calculate_rounded, title: 'Mathematics', subtitle: 'Fractions • ' + (currentMastery.score * 100).round().toString() + '% mastery'),
          _SubjectCard(icon: Icons.science_rounded, title: 'Science & Technology', subtitle: 'Ready to explore'),
          _SubjectCard(icon: Icons.menu_book_rounded, title: 'English', subtitle: 'Coming next'),
        ],
      ),
    );
  }
}

class FractionsScreen extends StatelessWidget {
  const FractionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fractions')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Fractions', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('5-minute lesson • Grade 6 Mathematics'),
          const SizedBox(height: 24),
          const Text('Learning objective', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Understand how to add fractions with the same denominator.'),
          const SizedBox(height: 24),
          const _ExampleCard(),
          const SizedBox(height: 24),
          const Text('Try it', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('What is 2/5 + 1/5?'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeScreen())),
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Check my answer')),
          ),
        ],
      ),
    );
  }
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String? selected;
  bool checked = false;
  bool recorded = false;

  @override
  Widget build(BuildContext context) {
    const options = ['1/5', '3/5', '3/10', '2/10'];
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Question 1 of 5', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('What is 2/5 + 1/5?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          ...options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  onPressed: () => setState(() => selected = option),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: selected == option ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.all(18),
                  ),
                  child: Align(alignment: Alignment.centerLeft, child: Text(option)),
                ),
              )),
          if (checked)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Correct! 2/5 + 1/5 = 3/5.', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          FilledButton(
            onPressed: selected == null ? null : () async {
              final correct = selected == '3/5';
              if (!recorded) {
                await appDatabase.saveAttempt(questionId: 'fractions-q1', correct: correct);
                currentMastery = TopicMastery(topicId: 'fractions', correct: currentMastery.correct + (correct ? 1 : 0), attempted: currentMastery.attempted + 1);
                recorded = true;
              }
              setState(() => checked = true);
            },
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Check answer')),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Example', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 12),
            Text('3/4 + 1/4 = 4/4 = 1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('When denominators are the same, add the numerators and keep the denominator.'),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final VoidCallback onTap;

  const _SectionCard({required this.title, required this.subtitle, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 6),
              Text(subtitle),
              const SizedBox(height: 14),
              LinearProgressIndicator(value: progress),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SubjectCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
