import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  List<TextEditingController> optionControllers = [TextEditingController()];
  bool isMultipleChoice = false;
  bool isAnonymous = false;
  DateTime? expiryDate;

  void addOption() {
    setState(() {
      optionControllers.add(TextEditingController());
    });
  }

  Future<void> createPoll() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final options = optionControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();

    if (title.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and at least 2 options are required.')),
      );
      return;
    }

    final pollData = {
      'title': title,
      'description': description,
      'options': options,
      'votes': {for (var opt in options) opt: 0},
      'isMultipleChoice': isMultipleChoice,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.now(),
      'expiresAt': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };

    try {
      await FirebaseFirestore.instance.collection('polls').add(pollData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll created successfully!')),
      );
      clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    optionControllers = [TextEditingController()];
    setState(() {
      isMultipleChoice = false;
      isAnonymous = false;
      expiryDate = null;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    for (var c in optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Create Poll")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Poll Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Poll Description'),
            ),
            const SizedBox(height: 20),
            const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...optionControllers.map(
                  (controller) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Option'),
                ),
              ),
            ),
            TextButton(onPressed: addOption, child: const Text('Add Option')),
            CheckboxListTile(
              title: const Text('Allow Multiple Choice'),
              value: isMultipleChoice,
              onChanged: (val) => setState(() => isMultipleChoice = val!),
            ),
            CheckboxListTile(
              title: const Text('Anonymous Voting'),
              value: isAnonymous,
              onChanged: (val) => setState(() => isAnonymous = val!),
            ),
            ListTile(
              title: Text(
                expiryDate == null
                    ? 'Set Expiry Date'
                    : 'Expires on: ${expiryDate!.toLocal()}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() => expiryDate = pickedDate);
                }
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: createPoll,
                child: const Text('Create Poll'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}