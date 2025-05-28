import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? displayName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      final nameFromFirestore = (doc.exists && data != null && data['displayName'] != null)
          ? data['displayName'] as String
          : null;

      setState(() {
        displayName = nameFromFirestore?.isNotEmpty == true
            ? nameFromFirestore
            : user.displayName ?? 'User';
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity, // stretch horizontally
        padding: EdgeInsets.only(top: 20), // some space from top
        child: Text(
          'Welcome, $displayName!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}