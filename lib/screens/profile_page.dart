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
  final _phoneNumberController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String _selectedCurrency = 'MYR';
  bool _darkMode = false;

  // Country codes list
  final List<String> _countryCodes = ['+60', '+1', '+44', '+91', '+81'];
  String _selectedCountryCode = '+60';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _displayNameController.text = data['displayName'] ?? '';
          _selectedCurrency = data['defaultCurrency'] ?? 'MYR';
          _monthlyBudgetController.text = (data['monthlyBudget'] ?? '').toString();
          _darkMode = data['darkMode'] ?? false;

          final fullPhone = data['phone'] ?? '';
          if (fullPhone.isNotEmpty) {
            // Detect country code from list or fallback
            final matchedCode = _countryCodes.firstWhere(
              (code) => fullPhone.startsWith(code),
              orElse: () => '+60',
            );
            _selectedCountryCode = matchedCode;
            _phoneNumberController.text = fullPhone.substring(matchedCode.length);
          } else {
            _selectedCountryCode = '+60';
            _phoneNumberController.text = '';
          }
        });
      } else {
        setState(() {
          _displayNameController.text = user.displayName ?? '';
          _selectedCurrency = 'MYR';
          _monthlyBudgetController.text = '2000';
          _darkMode = false;
          _selectedCountryCode = '+60';
          _phoneNumberController.text = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile.')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      // If form is invalid, do not save
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fullPhone = '$_selectedCountryCode${_phoneNumberController.text.trim()}';

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': _displayNameController.text,
      'defaultCurrency': _selectedCurrency,
      'monthlyBudget': int.tryParse(_monthlyBudgetController.text) ?? 0,
      'darkMode': _darkMode,
      'phone': fullPhone,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully!')),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // First confirmation dialog
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Second confirmation dialog
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('This is your last chance to cancel. Do you really want to delete your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (secondConfirm != true) return;

    try {
      // Delete user document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth user
      await user.delete();

      // Redirect to landing/login page
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log out and log in again before deleting your account.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while deleting the account.')),
      );
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final phone = value.trim();
    final numericRegex = RegExp(r'^[0-9]+$');
    if (!numericRegex.hasMatch(phone)) {
      return 'Phone number must be digits only';
    }
    if (phone.length < 6) {
      return 'Phone number is too short';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(labelText: 'Display Name'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Country code dropdown (fixed width)
                          Container(
                            width: 100,
                            child: DropdownButtonFormField<String>(
                              value: _selectedCountryCode,
                              decoration: InputDecoration(labelText: 'Code'),
                              items: ['+60', '+1', '+44', '+91', '+81'].map((code) {
                                return DropdownMenuItem(value: code, child: Text(code));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountryCode = value!;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          // Phone number input (flexible width)
                          Expanded(
                            child: TextFormField(
                              controller: _phoneNumberController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(labelText: 'Phone Number'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone number';
                                }
                                if (!RegExp(r'^\d+$').hasMatch(value)) {
                                  return 'Enter valid digits only';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(labelText: 'Default Currency'),
                        items: ['MYR', 'USD', 'EUR', 'SGD', 'JPY'].map((currency) {
                          return DropdownMenuItem(value: currency, child: Text(currency));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCurrency = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _monthlyBudgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Monthly Budget'),
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        title: const Text('Dark Mode'),
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
                    child: const Text('Save Profile'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _deleteAccount(context),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
