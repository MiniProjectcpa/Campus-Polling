import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'results_screen.dart';
import 'login_page.dart'; // Replace with your actual login page filename

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

      final Map<FieldPath, dynamic> updateData = {
        FieldPath(['votedUsers']): FieldValue.arrayUnion([userId]),
      };

      for (var option in selected) {
        updateData[FieldPath(['votes', option])] = FieldValue.increment(1);
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
    final votedUsers = poll['votedUsers'] ?? [];

    final cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color.fromRGBO(128, 128, 128, 0.1), // Subtle shadow for a modern effect
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll['title'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          if (poll['description'] != null && poll['description'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              child: Text(
                poll['description'],
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
          if (votedUsers.contains(userId)) ...[
            const Text("You have already voted.",
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade100,
                  foregroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PollResultsScreen(pollDoc: pollDoc),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text("View Results"),
              ),
            ),
          ] else ...[
            for (var option in options)
              isMultipleChoice
                  ? CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
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
                tileColor: Colors.purple.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                tileColor: Colors.purple.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 5,
                ),
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
                child: const Text("Submit Vote", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Voter Dashboard"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),

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
