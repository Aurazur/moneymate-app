import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'main_scaffold.dart';         // For regular users
import 'admin_scaffold.dart';       // For admins (use the scaffold with bottom nav)
import 'consultant_scaffold.dart';  // For consultants (use the scaffold with bottom nav)

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Not logged in
          return LoginPage();
        }

        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // If user data doesn't exist, treat as a normal user (or handle differently)
              return MainScaffold();
            }

            final userType = userSnapshot.data!.get('userType') ?? 'user';

            if (userType == 'admin') {
              return AdminScaffold();
            } else if (userType == 'consultant') {
              return ConsultantScaffold();
            } else {
              return MainScaffold(); // Default to regular user scaffold
            }
          },
        );
      },
    );
  }
}
