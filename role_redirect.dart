import 'package:flutter/material.dart';
import 'admin_screen.dart'; // Your actual poll creation screen
import 'voter_screen.dart'; // Your voter screen

class RoleBasedRedirect extends StatelessWidget {
  final String role;
  const RoleBasedRedirect({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == "admin") {
      return AdminScreen(); // removed const here
    } else {
      return VoterScreen(); // removed const here
    }
  }
}