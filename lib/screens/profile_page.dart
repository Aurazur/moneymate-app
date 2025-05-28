import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _displayNameController = TextEditingController();
  final _monthlyBudgetController = TextEditingController();
  String _selectedCurrency = 'MYR';
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _displayNameController.text = data['displayName'] ?? '';
          _selectedCurrency = data['defaultCurrency'] ?? 'MYR';
          _monthlyBudgetController.text = (data['monthlyBudget'] ?? '').toString();
          _darkMode = data['darkMode'] ?? false;
        });
      } else {
        setState(() {
          _displayNameController.text = user.displayName ?? '';
          _selectedCurrency = 'MYR';
          _monthlyBudgetController.text = '2000';
          _darkMode = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile.')),
      );
    }
  }


  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': _displayNameController.text,
      'defaultCurrency': _selectedCurrency,
      'monthlyBudget': int.tryParse(_monthlyBudgetController.text) ?? 0,
      'darkMode': _darkMode,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile saved successfully!')),
    );
  }

 Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _displayNameController,
                    decoration: InputDecoration(labelText: 'Display Name'),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(labelText: 'Default Currency'),
                    items: ['MYR', 'USD', 'EUR', 'SGD', 'JPY'].map((currency) {
                      return DropdownMenuItem(value: currency, child: Text(currency));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _monthlyBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Monthly Budget'),
                  ),
                  SizedBox(height: 20),
                  SwitchListTile(
                    title: Text('Dark Mode'),
                    value: _darkMode,
                    onChanged: (val) {
                      setState(() {
                        _darkMode = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Save Profile'),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

}
