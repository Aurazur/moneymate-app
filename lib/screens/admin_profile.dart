import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart'; // Import your login page

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({Key? key}) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'Admin Profile Page',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: ElevatedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
