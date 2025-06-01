import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({Key? key}) : super(key: key);

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  Map<String, int> counts = {
    'admin': 0,
    'consultant': 0,
    'user': 0,
  };
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserCounts();
  }

  Future<void> _fetchUserCounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    Map<String, int> newCounts = {'admin': 0, 'consultant': 0, 'user': 0};
    for (var doc in snapshot.docs) {
      final userType = doc.data()['userType'] as String? ?? 'user';
      if (newCounts.containsKey(userType)) {
        newCounts[userType] = newCounts[userType]! + 1;
      } else {
        newCounts['user'] = newCounts['user']! + 1;
      }
    }

    setState(() {
      counts = newCounts;
      loading = false;
    });
  }

  Widget _buildCard(String title, String userType) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(title),
        trailing: loading ? CircularProgressIndicator() : Text('${counts[userType]}'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserListPage(userType: userType, title: title),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildCard('Admins', 'admin'),
                _buildCard('Consultants', 'consultant'),
                _buildCard('Users', 'user'),
              ],
            ),
    );
  }
}

class UserListPage extends StatefulWidget {
  final String userType;
  final String title;

  const UserListPage({Key? key, required this.userType, required this.title}) : super(key: key);

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Stream<QuerySnapshot> _userStream;
  String _filter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userStream = _firestore
        .collection('users')
        .where('userType', isEqualTo: widget.userType)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by email',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase());
              },
            ),
          ),
          if (widget.userType == 'user')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<String>(
                value: _filter,
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'premium', child: Text('Premium Only')),
                  DropdownMenuItem(value: 'non-premium', child: Text('Non-Premium Only')),
                  DropdownMenuItem(value: 'premium-with-consultant', child: Text('Premium w/ Consultant')),
                  DropdownMenuItem(value: 'premium-without-consultant', child: Text('Premium w/o Consultant')),
                ],
                onChanged: (val) {
                  setState(() => _filter = val!);
                },
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _userStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading users'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs;
                final filteredUsers = users.where((doc) {
                  final email = doc['email']?.toLowerCase() ?? '';
                  if (!_searchQuery.isEmpty && !email.contains(_searchQuery)) return false;

                  if (widget.userType != 'user') return true;

                  final isPremium = doc['isPremium'] ?? false;
                  final hasConsultant = doc['assignedConsultant'] != null;

                  switch (_filter) {
                    case 'premium': return isPremium;
                    case 'non-premium': return !isPremium;
                    case 'premium-with-consultant': return isPremium && hasConsultant;
                    case 'premium-without-consultant': return isPremium && !hasConsultant;
                    default: return true;
                  }
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(child: Text('No ${widget.title.toLowerCase()} found.'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final userDoc = filteredUsers[index];
                    final email = userDoc['email'] ?? 'No Email';
                    final userId = userDoc.id;
                    final isPremium = userDoc['isPremium'] ?? false;
                    final consultantEmail = userDoc['assignedConsultant'] ?? null;

                    return ListTile(
                      leading: widget.userType == 'user'
                          ? Icon(Icons.star, color: isPremium ? Colors.amber : Colors.grey)
                          : null,
                      title: Text(email),
                      onTap: () async {
                        if (widget.userType == 'user') {
                          List<DocumentSnapshot> consultants = [];

                          try {
                            final consultantSnapshot = await _firestore
                                .collection('users')
                                .where('userType', isEqualTo: 'consultant')
                                .get();
                            consultants = consultantSnapshot.docs;
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error fetching consultants')),
                            );
                            return;
                          }

                          String? selectedConsultant = userDoc['assignedConsultant'];

                          final consultantEmails = consultants.map((doc) => doc['email'] as String).toList();
                          if (selectedConsultant != null && !consultantEmails.contains(selectedConsultant)) {
                            selectedConsultant = null;
                          }

                          showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: Text('Assign Consultant'),
                                content: StatefulBuilder(
                                  builder: (context, setState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DropdownButton<String>(
                                          isExpanded: true,
                                          value: selectedConsultant,
                                          hint: Text('Select a consultant'),
                                          items: consultantEmails.map((email) {
                                            return DropdownMenuItem<String>(
                                              value: email,
                                              child: Text(email),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() => selectedConsultant = value);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await _firestore.collection('users').doc(userId).update({
                                        'assignedConsultant': selectedConsultant,
                                      });
                                      Navigator.pop(context);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Consultant assigned successfully')),
                                      );
                                    },
                                    child: Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
