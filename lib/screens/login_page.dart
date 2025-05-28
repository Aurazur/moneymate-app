import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  Future<void> _login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    setState(() {
      _error = 'Email and password must not be empty.';
    });
    return;
  }

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    Navigator.pushReplacementNamed(context, '/dashboard');
  } catch (e) {
    setState(() {
      _error = e.toString();
    });
  }
  }
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return; // User canceled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() {
        _error = 'Google sign-in failed: $e';
      });
    }
  }

  void _showForgotPasswordDialog() {
  final TextEditingController _resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reset Password"),
        content: TextField(
          controller: _resetEmailController,
          decoration: InputDecoration(labelText: 'Enter your email'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final email = _resetEmailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Password reset email sent")),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              }
            },
            child: Text("Send Reset Email"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
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
                Image.asset(
                  'lib/assets/moneymate_logo.png',
                  width: 240, 
                  height: 240,
                ),
                //SizedBox(height: 24), 
                Text(
                  'Login',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 24), 
                TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
                TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Password')),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog, // Trigger the dialog
                    child: Text('Forgot Password?'),
                  ),
                ),
                ElevatedButton(onPressed: _login, child: Text('Login')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? "),
                    TextButton(onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    }, child: Text("Register"))
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 155, 153, 190),
                    padding: EdgeInsets.all(12),
                    minimumSize: Size(48, 48), // size of button
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.google,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
