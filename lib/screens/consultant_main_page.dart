import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConsultantMainPage extends StatelessWidget {
  const ConsultantMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final consultantEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('assignedConsultant', isEqualTo: consultantEmail)
            .where('isPremium', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading clients.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final clients = snapshot.data!.docs;

          if (clients.isEmpty) {
            return const Center(child: Text('No clients assigned to you.'));
          }

          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              final name = client['displayName'] ?? 'Unnamed';
              final email = client['email'] ?? 'No email';
              final phone = client['phone'] ?? 'No phone';
              final budget = client['monthlyBudget'] ?? 0;
              final currency = client['defaultCurrency'] ?? 'N/A';
              final isPremium = client['isPremium'] == true;

              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Email: $email'),
                      Text('Phone: $phone'),
                      Text('Budget: $currency $budget'),
                      Text('Premium: ${isPremium ? "Yes" : "No"}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
