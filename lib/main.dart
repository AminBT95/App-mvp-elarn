import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const LinguaPathApp());

const brandBlue = Color(0xFF246BFD);
const ink = Color(0xFF121826);
const muted = Color(0xFF687385);
const canvas = Color(0xFFF5F8FD);

class LinguaPathApp extends StatefulWidget {
  const LinguaPathApp({super.key});
  @override
  State<LinguaPathApp> createState() => _LinguaPathAppState();
}

class _LinguaPathAppState extends State<LinguaPathApp> {
  bool started = false;
  bool arabic = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinguaPath',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: brandBlue, surface: canvas),
        scaffoldBackgroundColor: canvas,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: ink,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ),
      home: Directionality(
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
        child: started
            ? MainShell(arabic: arabic, onLanguageChanged: (v) => setState(() => arabic = v))
            : WelcomeScreen(
                arabic: arabic,
                onLanguageChanged: (v) => setState(() => arabic = v),
                onStart: () => setState(() => started = true),
              ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final bool arabic;
  final ValueChanged<bool> onLanguageChanged;
  final VoidCallback onStart;
  const WelcomeScreen({super.key, required this.arabic, required this.onLanguageChanged, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(children: [const BrandMark(), const Spacer(), LanguagePill(arabic: arabic, onChanged: onLanguageChanged)]),
              const Spacer(),
              Container(
                width: 230,
                height: 230,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFE8F0FF), Color(0xFFF8FBFF)]),
                  shape: BoxShape.circle,
                ),
                child: Stack(alignment: Alignment.center, children: [
                  const Icon(Icons.public_rounded, size: 132, color: Color(0xFFB8CEFF)),
                  Transform.translate(
                    offset: const Offset(52, -44),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x33246BFD), blurRadius: 20)]),
                      child: const Icon(Icons.translate_rounded, color: Colors.white, size: 34),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 34),
              Text(arabic ? 'طريقك إلى الإنجليزية بثقة' : 'Your path to confident English', textAlign: TextAlign.center, style: const TextStyle(fontSize: 31, height: 1.12, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 14),
              Text(arabic ? 'دروس واضحة، تمارين عملية وتقدم يمكنك رؤيته كل يوم.' : 'Clear lessons, practical exercises and progress you can see every day.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.55, color: muted)),
              const Spacer(),
              FilledButton(onPressed: onStart, child: Text(arabic ? 'ابدأ التعلم' : 'Start learning')),
              const SizedBox(height: 14),
              Text(arabic ? 'لديك حساب؟ تسجيل الدخول' : 'Already have an account? Sign in', style: const TextStyle(color: brandBlue, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final bool arabic;
  final ValueChanged<bool> onLanguageChanged;
  const MainShell({super.key, required this.arabic, required this.onLanguageChanged});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  late Future<Map<String, dynamic>> data;
  final Set<String> completed = {'introductions'};
  final Set<String> saved = {'Break the ice'};
  final Set<String> downloads = {};
  bool premium = false;

  @override
  void initState() {
    super.initState();
    data = rootBundle.loadString('assets/data/catalog.json').then((value) => jsonDecode(value) as Map<String, dynamic>);
    _restoreLocalState();
  }

  Future<void> _restoreLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      completed
        ..clear()
        ..addAll(prefs.getStringList('completed') ?? ['introductions']);
      saved
        ..clear()
        ..addAll(prefs.getStringList('saved') ?? ['Break the ice']);
      downloads.addAll(prefs.getStringList('downloads') ?? []);
      premium = prefs.getBool('premium') ?? false;
    });
  }

  Future<void> _persistLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completed', completed.toList());
    await prefs.setStringList('saved', saved.toList());
    await prefs.setStringList('downloads', downloads.toList());
    await prefs.setBool('premium', premium);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final catalog = snapshot.data!;
        final screens = [
          HomeScreen(data: catalog, completed: completed, premium: premium, openCourse: openCourse, onNotifications: () => _push(const NotificationsScreen())),
          CoursesScreen(data: catalog, completed: completed, premium: premium, openCourse: openCourse),
          PracticeScreen(data: catalog, onCompleted: () => setState(() {}), onPlacement: () => _push(PlacementTestScreen(questions: List<Map<String, dynamic>>.from(catalog['questions'])))),
          PremiumScreen(active: premium, onActivate: () { setState(() => premium = true); _persistLocalState(); }),
          ProfileScreen(
            arabic: widget.arabic,
            onLanguageChanged: widget.onLanguageChanged,
            completed: completed.length,
            saved: saved.length,
            openProgress: () => _push(ProgressScreen(completed: completed.length)),
            openCertificates: () => _push(CertificatesScreen(eligible: completed.isNotEmpty)),
            openSaved: () => _push(SavedScreen(items: saved)),
            openDownloads: () => _push(DownloadsScreen(courses: List<Map<String, dynamic>>.from(catalog['courses']), downloaded: downloads, onToggle: (id) { setState(() => downloads.contains(id) ? downloads.remove(id) : downloads.add(id)); _persistLocalState(); })),
            openReminders: () => _push(const ReminderSettingsScreen()),
          ),
        ];
        return Scaffold(
          body: SafeArea(child: IndexedStack(index: index, children: screens)),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            indicatorColor: const Color(0xFFDDE8FF),
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Courses'),
              NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt_rounded), label: 'Practice'),
              NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium_rounded), label: 'Premium'),
              NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }

  void openCourse(Map<String, dynamic> course) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Directionality(
      textDirection: widget.arabic ? TextDirection.rtl : TextDirection.ltr,
      child: CourseDetailScreen(
        course: course,
        premium: premium,
        completed: completed,
        onComplete: (id) { setState(() => completed.add(id)); _persistLocalState(); },
        onPremium: () { Navigator.pop(context); setState(() => index = 3); },
      ),
    )));
  }

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Directionality(textDirection: widget.arabic ? TextDirection.rtl : TextDirection.ltr, child: screen)));
}

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final Set<String> completed;
  final bool premium;
  final ValueChanged<Map<String, dynamic>> openCourse;
  final VoidCallback onNotifications;
  const HomeScreen({super.key, required this.data, required this.completed, required this.premium, required this.openCourse, required this.onNotifications});

  @override
  Widget build(BuildContext context) {
    final courses = List<Map<String, dynamic>>.from(data['courses']);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Row(children: [const BrandMark(), const Spacer(), IconButton.filledTonal(onPressed: onNotifications, icon: const Icon(Icons.notifications_none_rounded, color: brandBlue))]),
        const SizedBox(height: 28),
        const Text('Good evening, Lina 👋', style: TextStyle(color: muted, fontSize: 15)),
        const SizedBox(height: 6),
        const Text('Ready for your next step?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1658E8), Color(0xFF397CFF)]), borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Text('CONTINUE LEARNING', style: TextStyle(color: Color(0xFFCFE0FF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)), Spacer(), Icon(Icons.auto_graph_rounded, color: Colors.white)]),
            const SizedBox(height: 18),
            const Text('General English A1', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('My daily routine', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            const LinearProgressIndicator(value: .35, minHeight: 7, borderRadius: BorderRadius.all(Radius.circular(8)), backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(Colors.white)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: () => openCourse(courses.first), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Continue · 12 min'), style: OutlinedButton.styleFrom(foregroundColor: brandBlue, backgroundColor: Colors.white, side: BorderSide.none)),
          ]),
        ),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Today’s plan', action: 'View all'),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(child: StatCard(icon: Icons.bolt_rounded, color: Color(0xFFF3A12B), value: '5', label: 'Daily practice')),
          SizedBox(width: 12),
          Expanded(child: StatCard(icon: Icons.local_fire_department_rounded, color: Color(0xFFEB5578), value: '7 days', label: 'Study streak')),
        ]),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Recommended for you', action: 'Explore'),
        const SizedBox(height: 12),
        ...courses.take(2).map((c) => CourseCard(course: c, onTap: () => openCourse(c))),
        const SizedBox(height: 18),
        const DailyWordCard(),
      ],
    );
  }
}

class CoursesScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final Set<String> completed;
  final bool premium;
  final ValueChanged<Map<String, dynamic>> openCourse;
  const CoursesScreen({super.key, required this.data, required this.completed, required this.premium, required this.openCourse});
  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final all = List<Map<String, dynamic>>.from(widget.data['courses']);
    final courses = filter == 'All' ? all : all.where((c) => c['level'] == filter).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 30), children: [
      PageHeader(title: 'Courses', subtitle: 'Find the right path for your goal', trailing: IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(data: widget.data, openCourse: widget.openCourse))), icon: const Icon(Icons.search_rounded))),
      const SizedBox(height: 22),
      SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: ['All','A1','A2','B1','B2','C1','C2'].map((f) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f), selectedColor: brandBlue, labelStyle: TextStyle(color: filter == f ? Colors.white : ink, fontWeight: FontWeight.w700), side: BorderSide.none, backgroundColor: Colors.white),
      )).toList())),
      const SizedBox(height: 20),
      ...courses.map((course) => CourseCard(course: course, onTap: () => widget.openCourse(course))),
      const SizedBox(height: 8),
      const SectionTitle(title: 'Learning library', action: 'See all'),
      const SizedBox(height: 12),
      ...List<Map<String, dynamic>>.from(widget.data['library']).map((item) => LibraryTile(item: item)),
    ]);
  }
}

class CourseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool premium;
  final Set<String> completed;
  final ValueChanged<String> onComplete;
  final VoidCallback onPremium;
  const CourseDetailScreen({super.key, required this.course, required this.premium, required this.completed, required this.onComplete, required this.onPremium});

  @override
  Widget build(BuildContext context) {
    final color = hexColor(course['color']);
    final lessons = List<Map<String, dynamic>>.from(course['lessons']);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar.large(
          expandedHeight: 245,
          pinned: true,
          backgroundColor: color,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(background: Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: .92), color])),
            padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Chip(label: Text(course['level']), backgroundColor: Colors.white, side: BorderSide.none, labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(course['title'], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(course['subtitle'], style: const TextStyle(color: Colors.white70, fontSize: 15)),
            ]),
          )),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList.list(children: [
            Row(children: [InfoPill(icon: Icons.schedule_rounded, text: '${lessons.length} lessons'), const SizedBox(width: 8), const InfoPill(icon: Icons.signal_cellular_alt_rounded, text: 'Self-paced')]),
            const SizedBox(height: 24),
            const Text('What you’ll learn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 10),
            const Text('Build useful language through clear explanations, real examples and practical exercises.', style: TextStyle(color: muted, height: 1.5)),
            const SizedBox(height: 24),
            const Text('Course lessons', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 12),
            ...lessons.asMap().entries.map((entry) {
              final lesson = entry.value;
              final locked = lesson['premium'] == true && !premium;
              final done = completed.contains(lesson['id']);
              return Card(child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: locked ? onPremium : () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson, onComplete: () => onComplete(lesson['id'])))),
                child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                  CircleAvatar(backgroundColor: done ? const Color(0xFFE7F8EF) : color.withValues(alpha: .1), child: Icon(done ? Icons.check_rounded : locked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded, color: done ? const Color(0xFF22A36A) : color)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${entry.key + 1}. ${lesson['title']}', style: const TextStyle(fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 5), Text('${lesson['type']} · ${lesson['duration']}', style: const TextStyle(color: muted, fontSize: 12))])),
                  const Icon(Icons.chevron_right_rounded, color: muted),
                ])),
              ));
            }),
          ]),
        ),
      ]),
    );
  }
}

class LessonScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback onComplete;
  const LessonScreen({super.key, required this.lesson, required this.onComplete});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool translation = true;
  bool playing = false;
  @override
  Widget build(BuildContext context) {
    final blocks = List<Map<String, dynamic>>.from(widget.lesson['blocks']);
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson['title']), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border_rounded))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), children: [
        Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: const LinearProgressIndicator(value: .55, minHeight: 7, backgroundColor: Color(0xFFE2E8F2)))), const SizedBox(width: 12), const Text('55%', style: TextStyle(color: muted, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFF102B62), borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            IconButton.filled(onPressed: () => setState(() => playing = !playing), icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: brandBlue)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Lesson audio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), SizedBox(height: 5), LinearProgressIndicator(value: .25, color: Color(0xFF6BA0FF), backgroundColor: Colors.white24)])),
            const SizedBox(width: 12),
            const Text('01:14', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        SwitchListTile(value: translation, onChanged: (v) => setState(() => translation = v), title: const Text('Show Arabic support', style: TextStyle(fontWeight: FontWeight.w700)), activeThumbColor: brandBlue, contentPadding: EdgeInsets.zero),
        const SizedBox(height: 6),
        ...blocks.where((b) => b['type'] != 'translation' || translation).map((block) => LessonBlock(block: block)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: () { widget.onComplete(); showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const CompletionSheet()); }, icon: const Icon(Icons.check_circle_outline_rounded), label: const Text('Complete lesson')),
      ]),
    );
  }
}

class PracticeScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onCompleted;
  final VoidCallback onPlacement;
  const PracticeScreen({super.key, required this.data, required this.onCompleted, required this.onPlacement});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 30), children: [
      const PageHeader(title: 'Practice', subtitle: 'A few minutes every day', trailing: Icon(Icons.insights_rounded)),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.bolt_rounded, color: Color(0xFFFFC54D)), Spacer(), Text('5 questions · 5 min', style: TextStyle(color: Colors.white70))]),
          const SizedBox(height: 24),
          const Text('Your daily challenge', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          const Text('Review vocabulary, grammar and reading.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(questions: List<Map<String, dynamic>>.from(data['questions'])))), child: const Text('Start practice')),
        ]),
      ),
      const SizedBox(height: 24),
      const SectionTitle(title: 'Practice by skill', action: ''),
      const SizedBox(height: 12),
      GridView.count(crossAxisCount: 2, childAspectRatio: 1.12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, children: const [
        SkillCard(icon: Icons.sort_by_alpha_rounded, title: 'Vocabulary', detail: '24 words', color: Color(0xFF246BFD)),
        SkillCard(icon: Icons.menu_book_rounded, title: 'Grammar', detail: '8 topics', color: Color(0xFF7357FF)),
        SkillCard(icon: Icons.headphones_rounded, title: 'Listening', detail: '12 activities', color: Color(0xFF00A6A6)),
        SkillCard(icon: Icons.mic_none_rounded, title: 'Speaking', detail: 'Self-review', color: Color(0xFFEB5578)),
      ]),
      const SizedBox(height: 24),
      const SectionTitle(title: 'Tests and review', action: ''),
      const SizedBox(height: 10),
      ActionTile(icon: Icons.assignment_rounded, title: 'Placement test', subtitle: 'Find your suggested starting level', onTap: onPlacement),
      const ActionTile(icon: Icons.error_outline_rounded, title: 'Review mistakes', subtitle: '6 questions to revisit'),
      const ActionTile(icon: Icons.history_rounded, title: 'Attempt history', subtitle: 'See scores and explanations'),
    ]);
  }
}

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  const QuizScreen({super.key, required this.questions});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int current = 0;
  int? selected;
  bool checked = false;
  int score = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.questions[current];
    final options = List<String>.from(q['options']);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily practice')),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: LinearProgressIndicator(value: (current + 1) / widget.questions.length, minHeight: 8, borderRadius: BorderRadius.circular(8))), const SizedBox(width: 12), Text('${current + 1}/${widget.questions.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: muted))]),
        const SizedBox(height: 36),
        Text(q['question'], style: const TextStyle(fontSize: 25, height: 1.25, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 24),
        ...options.asMap().entries.map((entry) {
          final isSelected = selected == entry.key;
          final isCorrect = checked && entry.key == q['answer'];
          final isWrong = checked && isSelected && !isCorrect;
          final border = isCorrect ? const Color(0xFF22A36A) : isWrong ? const Color(0xFFE04F5F) : isSelected ? brandBlue : const Color(0xFFDCE3EE);
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: checked ? null : () => setState(() => selected = entry.key),
            child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: isCorrect ? const Color(0xFFEAF8F1) : isWrong ? const Color(0xFFFFEFF1) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border, width: isSelected || isCorrect ? 2 : 1)), child: Row(children: [CircleAvatar(radius: 15, backgroundColor: border.withValues(alpha: .12), child: Text(String.fromCharCode(65 + entry.key), style: TextStyle(color: border, fontWeight: FontWeight.w800))), const SizedBox(width: 14), Expanded(child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700, color: ink))), if (isCorrect) const Icon(Icons.check_circle_rounded, color: Color(0xFF22A36A))])),
          ));
        }),
        if (checked) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(16)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_outline_rounded, color: brandBlue), const SizedBox(width: 10), Expanded(child: Text(q['explanation'], style: const TextStyle(color: ink, height: 1.4)))])),
        const Spacer(),
        FilledButton(onPressed: selected == null ? null : next, child: Text(checked ? (current == widget.questions.length - 1 ? 'See my result' : 'Next question') : 'Check answer')),
      ])),
    );
  }

  void next() {
    if (!checked) {
      setState(() { checked = true; if (selected == widget.questions[current]['answer']) score++; });
      return;
    }
    if (current < widget.questions.length - 1) {
      setState(() { current++; selected = null; checked = false; });
    } else {
      showDialog(context: context, builder: (_) => AlertDialog(icon: const Icon(Icons.emoji_events_rounded, size: 54, color: Color(0xFFF3A12B)), title: const Text('Practice complete!'), content: Text('You scored $score out of ${widget.questions.length}. Keep going!'), actions: [FilledButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Back to practice'))]));
    }
  }
}

class PremiumScreen extends StatelessWidget {
  final bool active;
  final VoidCallback onActivate;
  const PremiumScreen({super.key, required this.active, required this.onActivate});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 30), children: [
      const PageHeader(title: 'Go Premium', subtitle: 'Unlock your complete learning path', trailing: Icon(Icons.auto_awesome_rounded)),
      const SizedBox(height: 22),
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0B2250), Color(0xFF246BFD)]), borderRadius: BorderRadius.circular(26)), child: const Column(children: [Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD66B), size: 52), SizedBox(height: 14), Text('Learn without limits', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('Every course, every test and offline access — all in one plan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.45))])),
      const SizedBox(height: 22),
      const Benefit(icon: Icons.lock_open_rounded, text: 'Unlock all A1–C2 courses'),
      const Benefit(icon: Icons.download_for_offline_outlined, text: 'Download lessons for offline study'),
      const Benefit(icon: Icons.workspace_premium_outlined, text: 'Course tests and certificates'),
      const Benefit(icon: Icons.bar_chart_rounded, text: 'Detailed progress insights'),
      const SizedBox(height: 18),
      const PlanCard(title: 'Monthly', price: '49 DH', detail: 'per month', selected: false),
      const PlanCard(title: 'Yearly', price: '399 DH', detail: 'Save 32%', selected: true),
      const PlanCard(title: 'Lifetime', price: '899 DH', detail: 'One-time purchase', selected: false),
      const SizedBox(height: 12),
      FilledButton(onPressed: active ? null : onActivate, child: Text(active ? 'Premium active' : 'Start Premium demo')),
      const SizedBox(height: 12),
      const Center(child: Text('Restore purchases', style: TextStyle(color: brandBlue, fontWeight: FontWeight.w700))),
      const SizedBox(height: 8),
      const Text('Demo pricing only. Store billing will be connected in the production phase.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: muted)),
    ]);
  }
}

class ProfileScreen extends StatelessWidget {
  final bool arabic;
  final ValueChanged<bool> onLanguageChanged;
  final int completed;
  final int saved;
  final VoidCallback openProgress;
  final VoidCallback openCertificates;
  final VoidCallback openSaved;
  final VoidCallback openDownloads;
  final VoidCallback openReminders;
  const ProfileScreen({super.key, required this.arabic, required this.onLanguageChanged, required this.completed, required this.saved, required this.openProgress, required this.openCertificates, required this.openSaved, required this.openDownloads, required this.openReminders});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 30), children: [
      const PageHeader(title: 'Profile', subtitle: 'Your learning space', trailing: Icon(Icons.settings_outlined)),
      const SizedBox(height: 22),
      const Row(children: [CircleAvatar(radius: 34, backgroundColor: Color(0xFFDCE8FF), child: Text('L', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: brandBlue))), SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Lina Amrani', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)), SizedBox(height: 4), Text('Level A1 · 7 day streak', style: TextStyle(color: muted))]))]),
      const SizedBox(height: 22),
      Row(children: [Expanded(child: StatCard(icon: Icons.check_circle_rounded, color: const Color(0xFF22A36A), value: '$completed', label: 'Lessons done')), const SizedBox(width: 12), Expanded(child: StatCard(icon: Icons.bookmark_rounded, color: brandBlue, value: '$saved', label: 'Saved items'))]),
      const SizedBox(height: 24),
      const Text('Learning', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ink)),
      const SizedBox(height: 10),
      ActionTile(icon: Icons.insights_rounded, title: 'Progress and results', subtitle: 'Courses, skills and test history', onTap: openProgress),
      ActionTile(icon: Icons.workspace_premium_outlined, title: 'Certificates', subtitle: 'View and download achievements', onTap: openCertificates),
      ActionTile(icon: Icons.bookmark_border_rounded, title: 'Saved content', subtitle: 'Words, lessons and articles', onTap: openSaved),
      ActionTile(icon: Icons.download_outlined, title: 'Downloads', subtitle: 'Manage offline lessons', onTap: openDownloads),
      const SizedBox(height: 20),
      const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ink)),
      const SizedBox(height: 10),
      Card(child: SwitchListTile(value: arabic, onChanged: onLanguageChanged, secondary: const Icon(Icons.translate_rounded, color: brandBlue), title: const Text('Arabic interface', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('واجهة عربية واتجاه من اليمين'))),
      ActionTile(icon: Icons.notifications_none_rounded, title: 'Study reminders', subtitle: 'Daily practice and Word of the Day', onTap: openReminders),
      const ActionTile(icon: Icons.help_outline_rounded, title: 'Help and support', subtitle: 'FAQs, contact and report an issue'),
      const ActionTile(icon: Icons.shield_outlined, title: 'Privacy and account', subtitle: 'Terms, data and account deletion'),
    ]);
  }
}

class SearchScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> openCourse;
  const SearchScreen({super.key, required this.data, required this.openCourse});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final courses = List<Map<String, dynamic>>.from(widget.data['courses']).where((c) => '${c['title']} ${c['category']} ${c['level']}'.toLowerCase().contains(query.toLowerCase())).toList();
    final library = List<Map<String, dynamic>>.from(widget.data['library']).where((e) => '${e['title']} ${e['type']} ${e['level']}'.toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(appBar: AppBar(title: const Text('Search')), body: ListView(padding: const EdgeInsets.all(20), children: [
      TextField(autofocus: true, onChanged: (value) => setState(() => query = value), decoration: InputDecoration(hintText: 'Courses, lessons, articles…', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
      const SizedBox(height: 22),
      Text('${courses.length + library.length} results', style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (courses.isEmpty && library.isEmpty) const EmptyState(icon: Icons.search_off_rounded, title: 'No results found', detail: 'Try a level, skill or broader keyword.'),
      ...courses.map((course) => CourseCard(course: course, onTap: () { Navigator.pop(context); widget.openCourse(course); })),
      ...library.map((item) => LibraryTile(item: item)),
    ]));
  }
}

class PlacementTestScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  const PlacementTestScreen({super.key, required this.questions});
  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  int step = -1;
  int? selected;
  int score = 0;
  @override
  Widget build(BuildContext context) {
    if (step == -1) {
      return Scaffold(appBar: AppBar(), body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const Spacer(),
        const CircleAvatar(radius: 54, backgroundColor: Color(0xFFE8F0FF), child: Icon(Icons.route_rounded, size: 54, color: brandBlue)),
        const SizedBox(height: 24),
        const Text('Find your starting level', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: ink)),
        const SizedBox(height: 12),
        const Text('Answer 5 short questions. This gives a learning recommendation, not an official CEFR certificate.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5)),
        const Spacer(),
        FilledButton(onPressed: () => setState(() => step = 0), child: const Text('Start placement test')),
      ])));
    }
    if (step >= widget.questions.length) {
      final level = score <= 1 ? 'A1' : score <= 3 ? 'A2' : 'B1';
      return Scaffold(appBar: AppBar(), body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const Spacer(),
        const Icon(Icons.auto_graph_rounded, size: 74, color: brandBlue),
        const SizedBox(height: 22),
        const Text('Suggested starting point', style: TextStyle(fontSize: 20, color: muted)),
        const SizedBox(height: 8),
        Text(level, style: const TextStyle(fontSize: 62, fontWeight: FontWeight.w900, color: brandBlue)),
        Text('$score/${widget.questions.length} correct answers', style: const TextStyle(color: muted)),
        const SizedBox(height: 20),
        const Text('You can freely explore any level and change your learning path later.', textAlign: TextAlign.center, style: TextStyle(color: ink, height: 1.5)),
        const Spacer(),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Explore recommended courses')),
      ])));
    }
    final q = widget.questions[step];
    final options = List<String>.from(q['options']);
    return Scaffold(appBar: AppBar(title: const Text('Placement test')), body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LinearProgressIndicator(value: (step + 1) / widget.questions.length, minHeight: 8, borderRadius: BorderRadius.circular(8)),
      const SizedBox(height: 34),
      Text(q['question'], style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink)),
      const SizedBox(height: 22),
      ...options.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: RadioListTile<int>(value: e.key, groupValue: selected, onChanged: (v) => setState(() => selected = v), title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w700)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: selected == e.key ? brandBlue : const Color(0xFFDDE3EC), width: selected == e.key ? 2 : 1)), tileColor: Colors.white))),
      const Spacer(),
      FilledButton(onPressed: selected == null ? null : () => setState(() { if (selected == q['answer']) score++; step++; selected = null; }), child: const Text('Next')),
    ])));
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notifications')), body: ListView(padding: const EdgeInsets.all(20), children: const [
    ActionTile(icon: Icons.wb_sunny_outlined, title: 'Your daily word is ready', subtitle: 'Learn “resilient” and save it for review'),
    ActionTile(icon: Icons.bolt_rounded, title: 'Keep your 7-day streak', subtitle: 'Your daily practice takes about 5 minutes'),
    ActionTile(icon: Icons.menu_book_rounded, title: 'Continue your lesson', subtitle: 'My daily routine · 35% completed'),
    ActionTile(icon: Icons.new_releases_outlined, title: 'New Business English lesson', subtitle: 'Clear professional emails is now available'),
  ]));
}

class ProgressScreen extends StatelessWidget {
  final int completed;
  const ProgressScreen({super.key, required this.completed});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Progress and results')), body: ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1658E8), Color(0xFF397CFF)]), borderRadius: BorderRadius.circular(24)), child: Column(children: [const Text('GENERAL ENGLISH A1', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Text('$completed lessons', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 14), LinearProgressIndicator(value: (completed / 10).clamp(0.0, 1.0).toDouble(), minHeight: 8, color: Colors.white, backgroundColor: Colors.white24, borderRadius: BorderRadius.circular(8))])),
    const SizedBox(height: 22),
    const SectionTitle(title: 'Skills overview', action: ''),
    const SizedBox(height: 12),
    const ProgressSkill(label: 'Reading', value: .72, color: brandBlue),
    const ProgressSkill(label: 'Vocabulary', value: .58, color: Color(0xFF7357FF)),
    const ProgressSkill(label: 'Grammar', value: .46, color: Color(0xFF00A6A6)),
    const ProgressSkill(label: 'Listening', value: .34, color: Color(0xFFF3A12B)),
    const SizedBox(height: 20),
    const ActionTile(icon: Icons.history_rounded, title: 'Recent activity', subtitle: '3 lessons and 2 practice sessions this week'),
    const ActionTile(icon: Icons.emoji_events_outlined, title: '7-day study streak', subtitle: 'Your longest streak is 12 days'),
  ]));
}

class ProgressSkill extends StatelessWidget {
  final String label; final double value; final Color color;
  const ProgressSkill({super.key, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(children: [Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Text('${(value * 100).round()}%', style: TextStyle(color: color, fontWeight: FontWeight.w900))]), const SizedBox(height: 7), LinearProgressIndicator(value: value, minHeight: 8, color: color, backgroundColor: const Color(0xFFE6EBF3), borderRadius: BorderRadius.circular(8))]));
}

class CertificatesScreen extends StatelessWidget {
  final bool eligible;
  const CertificatesScreen({super.key, required this.eligible});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Certificates')), body: Padding(padding: const EdgeInsets.all(20), child: eligible ? ListView(children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFB9CCF3), width: 2)), child: const Column(children: [BrandMark(), SizedBox(height: 25), Text('CERTIFICATE OF COMPLETION', style: TextStyle(color: brandBlue, fontSize: 12, letterSpacing: 1.8, fontWeight: FontWeight.w900)), SizedBox(height: 18), Text('Lina Amrani', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: ink)), SizedBox(height: 7), Text('has completed the introductory module of', textAlign: TextAlign.center, style: TextStyle(color: muted)), SizedBox(height: 12), Text('General English A1', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink)), SizedBox(height: 22), Divider(), SizedBox(height: 12), Text('LP-DEMO-2026-001 · Demonstration record', style: TextStyle(fontSize: 11, color: muted))])),
    const SizedBox(height: 18),
    FilledButton.icon(onPressed: null, icon: Icon(Icons.picture_as_pdf_outlined), label: Text('PDF export in production phase')),
  ]) : const EmptyState(icon: Icons.workspace_premium_outlined, title: 'No certificate yet', detail: 'Complete an eligible course to unlock its certificate.')));
}

class SavedScreen extends StatelessWidget {
  final Set<String> items;
  const SavedScreen({super.key, required this.items});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Saved content')), body: items.isEmpty ? const EmptyState(icon: Icons.bookmark_border_rounded, title: 'Nothing saved yet', detail: 'Save words, lessons and articles to find them here.') : ListView(padding: const EdgeInsets.all(20), children: items.map((item) => ActionTile(icon: Icons.bookmark_rounded, title: item, subtitle: 'Saved vocabulary · Review today')).toList()));
}

class DownloadsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final Set<String> downloaded;
  final ValueChanged<String> onToggle;
  const DownloadsScreen({super.key, required this.courses, required this.downloaded, required this.onToggle});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Offline downloads')), body: ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.offline_bolt_rounded, color: brandBlue), SizedBox(width: 10), Expanded(child: Text('Downloaded courses remain available without internet in this local MVP.', style: TextStyle(color: ink, height: 1.4)))])),
    const SizedBox(height: 18),
    ...courses.map((course) { final active = downloaded.contains(course['id']); return Card(child: ListTile(contentPadding: const EdgeInsets.all(14), leading: CircleAvatar(backgroundColor: const Color(0xFFE8F0FF), child: Icon(active ? Icons.download_done_rounded : Icons.download_outlined, color: brandBlue)), title: Text(course['title'], style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${course['lessons'].length} lessons · approx. ${8 + course['lessons'].length * 3} MB'), trailing: Switch(value: active, onChanged: (_) => onToggle(course['id'])))); }),
  ]));
}

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});
  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool practice = true; bool dailyWord = true; bool course = false;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Study reminders')), body: ListView(padding: const EdgeInsets.all(20), children: [
    SwitchListTile(value: practice, onChanged: (v) => setState(() => practice = v), title: const Text('Daily practice', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Every day at 19:00'), secondary: const Icon(Icons.bolt_rounded, color: brandBlue)),
    SwitchListTile(value: dailyWord, onChanged: (v) => setState(() => dailyWord = v), title: const Text('Word of the Day', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Every morning at 09:00'), secondary: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFF3A12B))),
    SwitchListTile(value: course, onChanged: (v) => setState(() => course = v), title: const Text('Course updates', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('New lessons and content'), secondary: const Icon(Icons.menu_book_rounded, color: Color(0xFF7357FF))),
    const SizedBox(height: 16),
    const Text('These preferences are demonstrated locally. Scheduled device notifications are added before store release.', style: TextStyle(color: muted, height: 1.5)),
  ]));
}

class EmptyState extends StatelessWidget {
  final IconData icon; final String title; final String detail;
  const EmptyState({super.key, required this.icon, required this.title, required this.detail});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(36), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 58, color: const Color(0xFF9DB6E8)), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)), const SizedBox(height: 8), Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.5))])));
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [
    DecoratedBox(decoration: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.all(Radius.circular(8))), child: Padding(padding: EdgeInsets.all(7), child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 18))),
    SizedBox(width: 9), Text('LinguaPath', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
  ]);
}

class LanguagePill extends StatelessWidget {
  final bool arabic;
  final ValueChanged<bool> onChanged;
  const LanguagePill({super.key, required this.arabic, required this.onChanged});
  @override
  Widget build(BuildContext context) => SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('EN')), ButtonSegment(value: true, label: Text('ع'))], selected: {arabic}, onSelectionChanged: (v) => onChanged(v.first), style: const ButtonStyle(visualDensity: VisualDensity.compact));
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  const PageHeader({super.key, required this.title, required this.subtitle, required this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: ink)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: muted))])), CircleAvatar(backgroundColor: Colors.white, child: trailing)]);
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String action;
  const SectionTitle({super.key, required this.title, required this.action});
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink))), if (action.isNotEmpty) Text(action, style: const TextStyle(color: brandBlue, fontWeight: FontWeight.w700))]);
}

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  const CourseCard({super.key, required this.course, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = hexColor(course['color']);
    return Card(margin: const EdgeInsets.only(bottom: 12), child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(width: 58, height: 66, decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(16)), child: Icon(iconFor(course['icon']), color: color, size: 29)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(7)), child: Text(course['level'], style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11))), if (course['premium'] == true) const Padding(padding: EdgeInsets.only(left: 7), child: Icon(Icons.lock_rounded, size: 14, color: Color(0xFFF3A12B)))]), const SizedBox(height: 7), Text(course['title'], style: const TextStyle(fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 4), Text('${course['lessons'].length} lessons · ${course['category']}', style: const TextStyle(color: muted, fontSize: 12))])),
      const Icon(Icons.chevron_right_rounded, color: muted),
    ]))));
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const StatCard({super.key, required this.icon, required this.color, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ink)), const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 12, color: muted))])));
}

class DailyWordCard extends StatelessWidget {
  const DailyWordCard({super.key});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFFFF7E7), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFFFE4AE))), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.wb_sunny_outlined, color: Color(0xFFF3A12B)), SizedBox(width: 8), Text('WORD OF THE DAY', style: TextStyle(color: Color(0xFFB36B00), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)), Spacer(), Icon(Icons.bookmark_border_rounded, color: Color(0xFFB36B00))]), SizedBox(height: 16), Text('resilient', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink)), SizedBox(height: 6), Text('/rɪˈzɪl.i.ənt/ · adjective', style: TextStyle(color: muted)), SizedBox(height: 11), Text('Able to recover quickly from difficulties.', style: TextStyle(color: ink, height: 1.4))]));
}

class LibraryTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const LibraryTile({super.key, required this.item});
  @override
  Widget build(BuildContext context) { final color = hexColor(item['color']); return Card(child: ListTile(contentPadding: const EdgeInsets.all(13), leading: Container(width: 48, height: 54, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)), child: Icon(Icons.auto_stories_rounded, color: color)), title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text('${item['type']} · ${item['level']} · ${item['time']}')), trailing: const Icon(Icons.bookmark_border_rounded))); }
}

class LessonBlock extends StatelessWidget {
  final Map<String, dynamic> block;
  const LessonBlock({super.key, required this.block});
  @override
  Widget build(BuildContext context) {
    final type = block['type'];
    if (type == 'heading') return Padding(padding: const EdgeInsets.only(top: 16, bottom: 10), child: Text(block['text'], style: const TextStyle(fontSize: 25, height: 1.2, fontWeight: FontWeight.w900, color: ink)));
    if (type == 'translation') return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(16)), child: Text(block['text'], textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 17, height: 1.7, color: ink)));
    if (type == 'vocabulary') return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: const Color(0xFFEAF8F6), borderRadius: BorderRadius.circular(16)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.volume_up_outlined, color: Color(0xFF008E87)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(block['text'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)), const SizedBox(height: 5), Text(block['note'] ?? '', style: const TextStyle(color: muted, height: 1.4))])), const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF008E87))]));
    if (type == 'tip') return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: const Color(0xFFFFF7E7), borderRadius: BorderRadius.circular(16)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF3A12B)), const SizedBox(width: 12), Expanded(child: Text(block['text'], style: const TextStyle(color: ink, height: 1.5)))]));
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(block['text'], style: const TextStyle(fontSize: 17, color: ink, height: 1.65)));
  }
}

class CompletionSheet extends StatelessWidget {
  const CompletionSheet({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const CircleAvatar(radius: 40, backgroundColor: Color(0xFFE7F8EF), child: Icon(Icons.check_rounded, size: 44, color: Color(0xFF22A36A))), const SizedBox(height: 18), const Text('Lesson completed!', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink)), const SizedBox(height: 8), const Text('Great work. Your progress has been saved.', style: TextStyle(color: muted)), const SizedBox(height: 22), FilledButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Continue course'))])));
}

class SkillCard extends StatelessWidget {
  final IconData icon; final String title; final String detail; final Color color;
  const SkillCard({super.key, required this.icon, required this.title, required this.detail, required this.color});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(backgroundColor: color.withValues(alpha: .1), child: Icon(icon, color: color)), const Spacer(), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 4), Text(detail, style: const TextStyle(fontSize: 12, color: muted))])));
}

class ActionTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  final VoidCallback? onTap;
  const ActionTile({super.key, required this.icon, required this.title, required this.subtitle, this.onTap});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), leading: CircleAvatar(backgroundColor: const Color(0xFFEAF1FF), child: Icon(icon, color: brandBlue)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded)));
}

class Benefit extends StatelessWidget {
  final IconData icon; final String text;
  const Benefit({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [CircleAvatar(radius: 18, backgroundColor: const Color(0xFFE8F0FF), child: Icon(icon, size: 19, color: brandBlue)), const SizedBox(width: 12), Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: ink))]));
}

class PlanCard extends StatelessWidget {
  final String title; final String price; final String detail; final bool selected;
  const PlanCard({super.key, required this.title, required this.price, required this.detail, required this.selected});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? brandBlue : const Color(0xFFDDE3EC), width: selected ? 2 : 1)), child: Row(children: [Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? brandBlue : muted), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 3), Text(detail, style: const TextStyle(fontSize: 12, color: muted))])), Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink))]));
}

class InfoPill extends StatelessWidget {
  final IconData icon; final String text;
  const InfoPill({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 17, color: brandBlue), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink))]));
}

Color hexColor(String value) => Color(int.parse('FF$value', radix: 16));

IconData iconFor(String value) => switch (value) {
  'business_center' => Icons.business_center_rounded,
  'workspace_premium' => Icons.workspace_premium_rounded,
  'co_present' => Icons.co_present_rounded,
  'menu_book' => Icons.menu_book_rounded,
  _ => Icons.school_rounded,
};
