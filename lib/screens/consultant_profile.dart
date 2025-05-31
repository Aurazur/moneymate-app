import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';

class ConsultantProfilePage extends StatefulWidget {
  const ConsultantProfilePage({Key? key}) : super(key: key);

  @override
  State<ConsultantProfilePage> createState() => _ConsultantProfilePageState();
}

class _ConsultantProfilePageState extends State<ConsultantProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      final displayName = snapshot.data()?['displayName'] ?? '';
      setState(() {
        _nameController.text = displayName;
      });
    }
  }

  Future<void> _updateDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || _user == null) return;

    // Update Firebase Auth display name
    await _user!.updateDisplayName(newName);

    // Update Firestore profile
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .update({'displayName': newName});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Display name updated successfully')),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _updateDisplayName();
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
