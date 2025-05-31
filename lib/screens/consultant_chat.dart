import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultantChatPage extends StatelessWidget {
  const ConsultantChatPage({Key? key}) : super(key: key);

  static Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanedPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');

    // Android intent URL to launch WhatsApp directly
    final androidUrl = Uri.parse(
      "intent://send?phone=$cleanedPhone#Intent;scheme=smsto;package=com.whatsapp;end"
    );

    // Fallback to regular wa.me URL
    final fallbackUrl = Uri.parse("https://wa.me/$cleanedPhone");

    try {
      if (await canLaunchUrl(androidUrl)) {
        await launchUrl(androidUrl);
      } else if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch WhatsApp or fallback URL');
        throw 'Could not launch WhatsApp or fallback URL';
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      // Optionally show a message or handle error here
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentConsultantEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultees'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('users')
          .where('assignedConsultant', isEqualTo: currentConsultantEmail)
          .where('isPremium', isEqualTo: true)
          .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading users'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('No users assigned to you.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final email = user['email'] ?? 'No email';
              final username = user['displayName'] ?? 'No username';
              final phone = user['phone'] ?? '';

              return ListTile(
                title: Text(username),
                subtitle: Text('$email\n$phone'),
                isThreeLine: true,
                trailing: Icon(Icons.chat, color: Colors.green),
                onTap: () {
                  if (phone.isNotEmpty) {
                    _openWhatsApp(phone);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User has no phone number')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
