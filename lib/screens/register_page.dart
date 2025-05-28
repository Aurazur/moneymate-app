import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _error;

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
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
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Register', style: Theme.of(context).textTheme.displaySmall),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Colors.red)),
                TextField(controller: _usernameController, decoration: InputDecoration(labelText: 'Username')),
                TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
                TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'Phone Number')),
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
