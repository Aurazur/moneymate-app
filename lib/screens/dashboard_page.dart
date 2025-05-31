import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? displayName;
  bool isLoading = true;
  double budget = 0.0;
  String _searchQuery = '';
  bool _searchTriggered = false;
  String currency = 'RM';

  final TextEditingController _searchController = TextEditingController();
  String _selectedMonthFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();

      final nameFromFirestore =
          (doc.exists && data != null && data['displayName'] != null)
              ? data['displayName'] as String
              : null;

      setState(() {
        displayName = nameFromFirestore?.isNotEmpty == true
            ? nameFromFirestore
            : user.displayName ?? 'User';
        budget = (data?['monthlyBudget'] ?? 0).toDouble();
        currency = data?['defaultCurrency'] ?? 'RM';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text('User not logged in')));
    }

    final transactionsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true);

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: transactionsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading transactions'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;

                // Group transactions by month-year
                Map<String, List<DocumentSnapshot>> grouped = {};
                Set<String> allMonths = {};

                for (var doc in allDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  final monthKey = "${_monthName(date.month)} ${date.year}";

                  allMonths.add(monthKey);
                  if (_searchTriggered && _searchQuery.isNotEmpty) {
                    final title = data['title']?.toString().toLowerCase() ?? '';
                    if (!title.contains(_searchQuery.toLowerCase())) continue;
                  }

                  grouped.putIfAbsent(monthKey, () => []);
                  grouped[monthKey]!.add(doc);
                }

                List<String> sortedMonths = allMonths.toList()
                  ..sort((a, b) => _compareMonthYear(b, a)); // Descending

                final mostRecentMonth = sortedMonths.isNotEmpty ? sortedMonths.first : null;

                double totalExpense = 0.0;
                if (mostRecentMonth != null && grouped[mostRecentMonth] != null) {
                  for (var doc in grouped[mostRecentMonth]!) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['type'] == 'Expense') {
                      final amount = data['amount'] as num? ?? 0;
                      totalExpense += amount.toDouble();
                    }
                  }
                }

                final remaining = budget - totalExpense;


                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search transactions...',
                                border: OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.search),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = _searchController.text;
                                      _searchTriggered = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Welcome, $displayName!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      'Monthly Budget: $currency ${budget.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                    Text(
                      'Remaining: $currency ${remaining.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, color: Colors.green),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(thickness: 1.5, color: Colors.grey),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Filter by month: "),
                          DropdownButton<String>(
                            value: _selectedMonthFilter,
                            items: ['All', ...sortedMonths].map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMonthFilter = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sortedMonths.length,
                        itemBuilder: (context, index) {
                          final month = sortedMonths[index];

                          if (_selectedMonthFilter != 'All' &&
                              _selectedMonthFilter != month) {
                            return SizedBox.shrink();
                          }

                          final transactions = grouped[month] ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                                child: Text(
                                  month,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              transactions.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('No transactions found'),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: transactions.length,
                                      itemBuilder: (context, idx) {
                                        final doc = transactions[idx];
                                        final data = doc.data() as Map<String, dynamic>;
                                        final title = data['title'] ?? 'Untitled';
                                        final amount = (data['amount'] as num?)
                                                ?.toDouble()
                                                .toStringAsFixed(2) ??
                                            '0.00';
                                        final date =
                                            (data['date'] as Timestamp).toDate();
                                        final type = data['type'] ?? 'unknown';

                                        return Dismissible(
                                          key: Key(doc.id),
                                          direction: DismissDirection.endToStart,
                                          background: Container(
                                            color: Colors.red,
                                            alignment: Alignment.centerRight,
                                            padding: EdgeInsets.only(right: 20),
                                            child: Icon(Icons.delete, color: Colors.white),
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: Text('Delete Transaction'),
                                                content: Text(
                                                    'Are you sure you want to delete this transaction?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx).pop(false),
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx).pop(true),
                                                    child: Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          onDismissed: (direction) async {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user.uid)
                                                .collection('transactions')
                                                .doc(doc.id)
                                                .delete();

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text('Transaction deleted'),
                                            ));
                                          },
                                          child: ListTile(
                                            leading: Icon(
                                              type.toLowerCase() == 'expense'
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward,
                                              color: type.toLowerCase() == 'expense'
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            title: Text(title),
                                            subtitle: Text(
                                              '${type.toUpperCase()} • ${date.toLocal().toString().split(' ')[0]}',
                                            ),
                                            trailing: Text(
                                              '$currency $amount',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: type.toLowerCase() == 'expense'
                                                    ? Colors.red
                                                    : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  int _compareMonthYear(String a, String b) {
    final partsA = a.split(' ');
    final partsB = b.split(' ');
    final yearA = int.tryParse(partsA[1]) ?? 0;
    final yearB = int.tryParse(partsB[1]) ?? 0;
    final monthA = _monthToNumber(partsA[0]);
    final monthB = _monthToNumber(partsB[0]);

    if (yearA != yearB) return yearA.compareTo(yearB);
    return monthA.compareTo(monthB);
  }

  int _monthToNumber(String month) {
    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };
    return months[month] ?? 0;
  }
}