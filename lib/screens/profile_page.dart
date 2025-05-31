import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User profile data
  String _displayName = '';
  String _phone = '';
  String _selectedCountryCode = '+60';
  String _selectedCurrency = 'MYR';
  String _monthlyBudget = '';

  final List<String> _countryCodes = ['+60', '+1', '+44', '+91', '+81'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _displayName = data['displayName'] ?? '';
          _selectedCurrency = data['defaultCurrency'] ?? 'MYR';
          _monthlyBudget = (data['monthlyBudget'] ?? '').toString();

          final fullPhone = data['phone'] ?? '';
          if (fullPhone.isNotEmpty) {
            final matchedCode = _countryCodes.firstWhere(
              (code) => fullPhone.startsWith(code),
              orElse: () => '+60',
            );
            _selectedCountryCode = matchedCode;
            _phone = fullPhone.substring(matchedCode.length);
          } else {
            _selectedCountryCode = '+60';
            _phone = '';
          }
        });
      } else {
        setState(() {
          _displayName = user.displayName ?? '';
          _selectedCurrency = 'MYR';
          _monthlyBudget = '2000';
          _selectedCountryCode = '+60';
          _phone = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile.')),
      );
    }
  }

  Future<void> _updateLocalProfile({
    required String displayName,
    required String phone,
    required String countryCode,
    required String currency,
    required String monthlyBudget,
  }) async {
    setState(() {
      _displayName = displayName;
      _phone = phone;
      _selectedCountryCode = countryCode;
      _selectedCurrency = currency;
      _monthlyBudget = monthlyBudget;
    });
  }

  Future<void> _saveProfile(String displayName, String countryCode, String phone,
      String currency, String monthlyBudget) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fullPhone = '$countryCode${phone.trim()}';

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': displayName,
      'defaultCurrency': currency,
      'monthlyBudget': int.tryParse(monthlyBudget) ?? 0,
      'phone': fullPhone,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully!')),
    );

    // Update the main page's local state
    _updateLocalProfile(
      displayName: displayName,
      phone: phone,
      countryCode: countryCode,
      currency: currency,
      monthlyBudget: monthlyBudget,
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
            'This is your last chance to cancel. Do you really want to delete your account?'),
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
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();

      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please log out and log in again before deleting your account.')),
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

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
            elevation: 0, // Remove AppBar shadow / grey bar
            leading: BackButton(), // Back arrow automatically pops the screen
          ),
          body: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: _EditProfileForm(
              initialDisplayName: _displayName,
              initialCountryCode: _selectedCountryCode,
              initialPhone: _phone,
              initialCurrency: _selectedCurrency,
              initialMonthlyBudget: _monthlyBudget,
              countryCodes: _countryCodes,
              onSave: (displayName, countryCode, phone, currency, monthlyBudget) async {
                await _saveProfile(displayName, countryCode, phone, currency, monthlyBudget);
                Navigator.pop(context);
              },
              onCancel: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _displayName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_selectedCountryCode$_phone',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton.icon(
                  icon: const Icon(Icons.account_circle),
                  label: const Text(
                    'Account Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: _openEditProfile,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton.icon(
                  icon: const Icon(Icons.help),
                  label: const Text(
                    'Help & Support',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpAndSupportPage()),
                  ),
                ),
              ),
            ),

          


            const Spacer(),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () => _logout(context),
                ),
              ),
            ),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.redAccent),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.redAccent,
                  ),
                  onPressed: () => _deleteAccount(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class HelpAndSupportPage extends StatelessWidget {
  const HelpAndSupportPage({Key? key}) : super(key: key);

  final String appVersion = '1.0.0'; // Replace with your actual app version

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.contact_support, color: Colors.blue),
                title: const Text(
                  'Contact Support',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text('moneymatehelpline@gmail.com\n+60 16 298 2609'),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.green),
                title: const Text(
                  'App Version',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(appVersion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  final String initialDisplayName;
  final String initialCountryCode;
  final String initialPhone;
  final String initialCurrency;
  final String initialMonthlyBudget;
  final List<String> countryCodes;
  final Future<void> Function(String, String, String, String, String) onSave;
  final VoidCallback onCancel;

  const _EditProfileForm({
    Key? key,
    required this.initialDisplayName,
    required this.initialCountryCode,
    required this.initialPhone,
    required this.initialCurrency,
    required this.initialMonthlyBudget,
    required this.countryCodes,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  late TextEditingController _monthlyBudgetController;
  late String _selectedCountryCode;
  late String _selectedCurrency;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.initialDisplayName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _monthlyBudgetController = TextEditingController(text: widget.initialMonthlyBudget);
    _selectedCountryCode = widget.initialCountryCode;
    _selectedCurrency = widget.initialCurrency;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Phone number must be digits only';
    }
    return null;
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a display name';
    }
    return null;
  }

  String? _validateMonthlyBudget(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a monthly budget';
    }
    if (int.tryParse(value) == null) {
      return 'Monthly budget must be a number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal top bar with handle and close button
            
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Display Name
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateDisplayName,
                  ),
                  const SizedBox(height: 16),

                  // Phone Number with Country Code Picker
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          underline: const SizedBox.shrink(),
                          items: widget.countryCodes
                              .map(
                                (code) => DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(code),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCountryCode = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Default Currency
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Default Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: <String>['MYR', 'USD', 'EUR', 'JPY', 'GBP']
                        .map((currency) => DropdownMenuItem<String>(
                              value: currency,
                              child: Text(currency),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Monthly Budget
                  TextFormField(
                    controller: _monthlyBudgetController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Budget',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateMonthlyBudget,
                  ),
                  const SizedBox(height: 24),

                  // Buttons: Save and Cancel
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onCancel,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onSave(
                                _displayNameController.text.trim(),
                                _selectedCountryCode,
                                _phoneController.text.trim(),
                                _selectedCurrency,
                                _monthlyBudgetController.text.trim(),
                              );
                            }
                          },
                          child: const Text('Save Profile'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}