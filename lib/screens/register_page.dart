import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedCountryCode = '+60';
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _error;

  Future<void> _register() async {
    if (_phoneController.text.isEmpty || !_phoneController.text.trim().contains(RegExp(r'^\d{6,}$'))) {
      setState(() {
        _error = 'Enter a valid phone number';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _usernameController.text.trim(),
          'defaultCurrency': 'MYR',
          'monthlyBudget': 1000,
          'darkMode': false,
          'createdAt': FieldValue.serverTimestamp(),
          'email': _emailController.text.trim(),
          'phone': '$_selectedCountryCode${_phoneController.text.trim()}',
          'userType': 'user',
          'isPremium': false,
          'assignedConsultant': null,
        });

        await user.sendEmailVerification();

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Verify your email'),
            content: Text(
              'A verification link has been sent to ${user.email}. Please verify your email before continuing.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );

        await FirebaseAuth.instance.signOut();

        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      String message = 'Registration failed';
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          message = 'This email is already registered.';
        } else if (e.code == 'weak-password') {
          message = 'The password is too weak.';
        } else if (e.code == 'invalid-email') {
          message = 'The email format is invalid.';
        }
      }

      setState(() {
        _error = message;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Register', style: Theme.of(context).textTheme.displaySmall),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Colors.red)),
                TextField(controller: _usernameController, decoration: InputDecoration(labelText: 'Username')),
                TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
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
                TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Password')),
                TextField(controller: _confirmPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'Confirm Password')),
                SizedBox(height: 24), 
                ElevatedButton(onPressed: _register, child: Text('Register')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? "),
                    TextButton(onPressed: () {
                      Navigator.pop(context);
                    }, child: Text("Sign In"))
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
