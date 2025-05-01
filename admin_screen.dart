import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

    final sanitizedOptions = options.map((e) => e.replaceAll('.', '_dot_')).toList();

    final pollData = {
      'title': title,
      'description': description,
      'options': sanitizedOptions,
      'votes': {for (var opt in sanitizedOptions) opt: 0},
      'votedUsers': [],
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
    final cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.deepPurple.withAlpha(25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text("Poller - Create Poll"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: cardDecoration,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInput(titleController, 'Poll Title'),
              const SizedBox(height: 12),
              _buildInput(descriptionController, 'Poll Description'),
              const SizedBox(height: 20),
              const Text('Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...optionControllers.map(
                    (controller) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildInput(controller, 'Option'),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, color: Colors.deepPurple),
                label: const Text('Add Option', style: TextStyle(color: Colors.deepPurple)),
                onPressed: addOption,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Allow Multiple Choice'),
                value: isMultipleChoice,
                activeColor: Colors.deepPurple,
                onChanged: (val) => setState(() => isMultipleChoice = val!),
              ),
              CheckboxListTile(
                title: const Text('Anonymous Voting'),
                value: isAnonymous,
                activeColor: Colors.deepPurple,
                onChanged: (val) => setState(() => isAnonymous = val!),
              ),
              ListTile(
                title: Text(
                  expiryDate == null
                      ? 'Set Expiry Date'
                      : 'Expires on: ${DateFormat.yMMMd().format(expiryDate!)}',
                  style: const TextStyle(fontSize: 15),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.deepPurple),
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
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text("Create Poll", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                  ),
                  onPressed: createPoll,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF0F0F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
