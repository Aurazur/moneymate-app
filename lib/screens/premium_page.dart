import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  late Future<Map<String, dynamic>?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data();
  }

  Future<Map<String, dynamic>?> _getConsultantByEmail(String email) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  Future<void> _simulatePremiumPurchase() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2)); 

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'isPremium': true});
    }

    Navigator.of(context).pop(); 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your purchase was successful!')),
      );
      setState(() {
        _userDataFuture = _getUserData(); 
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'isPremium': false});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We hope to see you again soon!')),
      );
      setState(() {
        _userDataFuture = _getUserData(); 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading user data'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!;
        final isPremium = userData['isPremium'] ?? false;

        if (!isPremium) {
          return _buildNonPremiumView(context);
        }

        final assignedConsultantEmail = userData['assignedConsultant'];

        if (assignedConsultantEmail == null || assignedConsultantEmail == '') {
          return _buildThankYouAndMessage(
            context,
            const Text(
              "Your consultant hasn't been assigned yet, but we'll get to you shortly! Thank you for your patience.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _getConsultantByEmail(assignedConsultantEmail),
          builder: (context, consultantSnapshot) {
            if (consultantSnapshot.hasError) {
              return const Center(child: Text('Error loading consultant info'));
            }

            if (!consultantSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final consultant = consultantSnapshot.data!;
            final name = consultant['displayName'] ?? 'Unknown';
            final email = consultant['email'] ?? 'Unknown';
            final phone = consultant['phone'] ?? 'No phone provided';

            return _buildThankYouAndMessage(
              context,
              Column(
                children: [
                  const Text(
                    "Your consultant is:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(email, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(phone, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNonPremiumView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.amber.shade700),
          const SizedBox(height: 20),
          Text(
            "Don't have MoneyMate Premium?",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Get it now!",
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _simulatePremiumPurchase,
            child: const Text('Buy Premium'),
          ),
          const SizedBox(height: 20),
          const Text(
            "MoneyMate Premium is a monthly subscription which gives you access to certified consultants to help better your savings!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouAndMessage(BuildContext context, Widget messageWidget) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.amber.shade700),
          const SizedBox(height: 20),
          const Text(
            "Thanks for purchasing MoneyMate Premium!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: messageWidget,
          ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: _cancelSubscription,
            child: const Text(
              "Cancel Subscription",
              style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          )
        ],
      ),
    );
  }
}
