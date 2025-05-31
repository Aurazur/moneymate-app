import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddNewPage extends StatefulWidget {
  const AdminAddNewPage({Key? key}) : super(key: key);

  @override
  _AdminAddNewPageState createState() => _AdminAddNewPageState();
}

class _AdminAddNewPageState extends State<AdminAddNewPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+60';
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Admin password only now (email auto loaded)
  final _adminPasswordController = TextEditingController();

  String? _userType = 'admin'; // default user type
  String? _error;

  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _loadAdminEmail();
  }

  void _loadAdminEmail() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && mounted) {
      setState(() {
        _adminEmail = currentUser.email;
      });
    } else {
      setState(() {
        _error = "No admin user is currently signed in.";
      });
    }
  }

  Future<void> _createUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }
    if (_phoneController.text.isEmpty || !_phoneController.text.trim().contains(RegExp(r'^\d{6,}$'))) {
      setState(() {
        _error = 'Enter a valid phone number';
      });
      return;
    }
    if (_adminEmail == null || _adminPasswordController.text.isEmpty) {
      setState(() {
        _error = 'Admin password is required for re-login';
      });
      return;
    }

    try {
      // Create new user account
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        // Save user info to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': '$_selectedCountryCode${_phoneController.text.trim()}',
          'userType': _userType,
          'createdAt': FieldValue.serverTimestamp(),
          'isPremium': false,
          'assignedConsultant': null,
        });

        // Sign out the new user
        await FirebaseAuth.instance.signOut();

        // Sign back in as admin
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _adminEmail!,
          password: _adminPasswordController.text,
        );

        setState(() {
          _error = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New user created successfully. Signed back in as admin.')),
        );

        // Optionally clear inputs
        _usernameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _adminPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to create user.';
      if (e.code == 'email-already-in-use') {
        message = 'Email already registered.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      }

      setState(() {
        _error = message;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              Row(
                children: [
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
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm Password'),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'User Type'),
                value: _userType,
                items: [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'consultant', child: Text('Consultant')),
                ],
                onChanged: (value) {
                  setState(() {
                    _userType = value;
                  });
                },
              ),

              Divider(height: 32),
              Text('Admin Re-login (required)'),

              // Show admin email as text
              if (_adminEmail != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Admin Email: $_adminEmail', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                CircularProgressIndicator(),

              TextField(
                controller: _adminPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Admin Password'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createUser,
                child: Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
