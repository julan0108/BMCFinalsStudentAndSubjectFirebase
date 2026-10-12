import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Registration',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const PageForm(),
    );
  }
}

class PageForm extends StatefulWidget {
  const PageForm({super.key});

  @override
  State<PageForm> createState() => _PageFormState();
}

class _PageFormState extends State<PageForm> {
  final nameController = TextEditingController();
  final sectionController = TextEditingController();
  final yearController = TextEditingController();

  final subjects = List.generate(
    3,
    (_) => TextEditingController(),
  );

  final schedules = List.generate(
    3,
    (_) => TextEditingController(),
  );

  int page = 0;
  bool saving = false;

  @override
  void dispose() {
    nameController.dispose();
    sectionController.dispose();
    yearController.dispose();

    for (final c in subjects) {
      c.dispose();
    }

    for (final c in schedules) {
      c.dispose();
    }

    super.dispose();
  }

  Future<void> saveStudent() async {
    if (nameController.text.trim().isEmpty ||
        sectionController.text.trim().isEmpty ||
        yearController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the student information.'),
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final subjectList = <Map<String, String>>[];

      for (int i = 0; i < 3; i++) {
        if (subjects[i].text.trim().isNotEmpty ||
            schedules[i].text.trim().isNotEmpty) {
          subjectList.add({
            'subject': subjects[i].text.trim(),
            'schedule': schedules[i].text.trim(),
          });
        }
      }

      await FirebaseFirestore.instance
          .collection('students')
          .add({
        'name': nameController.text.trim(),
        'section': sectionController.text.trim(),
        'yearLevel': yearController.text.trim(),
        'subjects': subjectList,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student saved successfully!'),
        ),
      );

      nameController.clear();
      sectionController.clear();
      yearController.clear();

      for (final c in subjects) {
        c.clear();
      }

      for (final c in schedules) {
        c.clear();
      }

      setState(() => page = 0);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving student: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget input(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          page == 0
              ? 'Student Registration'
              : 'Subject Schedule',
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (page == 0) ...[
                const Icon(
                  Icons.school,
                  size: 70,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 20),

                input('Name', nameController),
                input('Section', sectionController),
                input('Year Level', yearController),

                const SizedBox(height: 10),

                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty ||
                          sectionController.text.trim().isEmpty ||
                          yearController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please complete all student information.',
                            ),
                          ),
                        );
                      } else {
                        setState(() => page = 1);
                      }
                    },
                    child: const Text('Next'),
                  ),
                ),
              ] else ...[
                for (int i = 0; i < 3; i++) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject ${i + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          input('Subject', subjects[i]),
                          input('Schedule', schedules[i]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                OutlinedButton(
                  onPressed: saving
                      ? null
                      : () => setState(() => page = 0),
                  child: const Text('Back'),
                ),

                const SizedBox(height: 8),

                FilledButton.icon(
                  onPressed: saving ? null : saveStudent,
                  icon: const Icon(Icons.save),
                  label: Text(
                    saving ? 'Saving...' : 'Save Student',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
