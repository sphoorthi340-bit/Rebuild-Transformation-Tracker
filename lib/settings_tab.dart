import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  // Log out function
  Future<void> logOut(BuildContext context) async {
    // Pop the settings page first
    Navigator.pop(context); 
    // Wait for 100ms for the drawer to close
    await Future.delayed(const Duration(milliseconds: 100)); 
    // Sign out
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- LOG OUT BUTTON ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out'),
            onTap: () => logOut(context),
          ),
          // We can add more settings here later (e.g., "Edit Profile")
        ],
      ),
    );
  }
}