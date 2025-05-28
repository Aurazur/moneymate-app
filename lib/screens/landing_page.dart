import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'main_scaffold.dart';

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is signed in, go to dashboard
      return MainScaffold();
    } else {
      // Not signed in, go to login
      return LoginPage();
    }
  }
}
