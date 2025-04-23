import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VoterScreen extends StatefulWidget {
  const VoterScreen({super.key});

  @override
  State<VoterScreen> createState() => _VoterScreenState();
}

class _VoterScreenState extends State<VoterScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, dynamic> _selectedOptions = {}; // pollId -> selection

  Future<void> _submitVote(String pollId, List<String> selected) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final pollRef = _firestore.collection('polls').doc(pollId);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final pollSnapshot = await pollRef.get();
      if (!pollSnapshot.exists) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Poll no longer exists.")),
        );
        return;
      }

      final pollData = pollSnapshot.data()!;
      final List<dynamic> votedUsers = pollData['votedUsers'] ?? [];

      if (votedUsers.contains(userId)) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("You have already voted on this poll.")),
        );
        return;
      }

      final Map<String, dynamic> updateData = {
        'votedUsers': FieldValue.arrayUnion([userId]),
      };

      for (var option in selected) {
        updateData['votes.$option'] = FieldValue.increment(1);
      }

      await pollRef.update(updateData);

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Vote submitted successfully!")),
      );

      setState(() {
        _selectedOptions.remove(pollId);
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Failed to submit vote. Please try again.")),
      );
    }
  }

  Widget _buildPollItem(DocumentSnapshot pollDoc) {
    final poll = pollDoc.data() as Map<String, dynamic>;
    final pollId = pollDoc.id;
    final options = List<String>.from(poll['options']);
    final isMultipleChoice = poll['isMultipleChoice'] ?? false;
    final userId = _auth.currentUser?.uid ?? '';

    List votedUsers = poll['votedUsers'] ?? [];

    if (votedUsers.contains(userId)) {
      return Card(
        margin: const EdgeInsets.all(8),
        child: ListTile(
          title: Text(poll['title']),
          subtitle: const Text("You have already voted."),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poll['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (poll['description'] != null && poll['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(poll['description']),
              ),
            const SizedBox(height: 10),
            for (var option in options)
              isMultipleChoice
                  ? CheckboxListTile(
                value: (_selectedOptions[pollId] ?? <String>[]).contains(option),
                onChanged: (val) {
                  setState(() {
                    List<String> selected = (_selectedOptions[pollId] ?? <String>[]).cast<String>();
                    if (val == true) {
                      selected.add(option);
                    } else {
                      selected.remove(option);
                    }
                    _selectedOptions[pollId] = selected;
                  });
                },
                title: Text(option),
              )
                  : RadioListTile<String>(
                value: option,
                groupValue: _selectedOptions[pollId],
                onChanged: (val) {
                  setState(() {
                    _selectedOptions[pollId] = val;
                  });
                },
                title: Text(option),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                var selection = _selectedOptions[pollId];
                if (isMultipleChoice) {
                  if (selection == null || (selection as List).isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select at least one option.")),
                    );
                    return;
                  }
                  _submitVote(pollId, List<String>.from(selection));
                } else {
                  if (selection == null || selection.toString().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select an option.")),
                    );
                    return;
                  }
                  _submitVote(pollId, [selection]);
                }
              },
              child: const Text("Submit Vote"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voter Dashboard")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('polls').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading polls"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final polls = snapshot.data!.docs;

          if (polls.isEmpty) return const Center(child: Text("No polls available"));

          return ListView(
            children: polls.map(_buildPollItem).toList(),
          );
        },
      ),
    );
  }
}