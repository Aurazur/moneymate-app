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
  DateTime _selectedMonth = DateTime.now(); // New: to hold selected month

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
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

  void _pickMonth(BuildContext context) async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text('User not logged in')));
    }

    final firstOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      1,
    );

    final transactionsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(nextMonth))
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

                final allTransactions = snapshot.data!.docs;

                final transactions = _searchTriggered && _searchQuery.isNotEmpty
                    ? allTransactions.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title =
                            data['title']?.toString().toLowerCase() ?? '';
                        return title.contains(_searchQuery.toLowerCase());
                      }).toList()
                    : allTransactions;

                double totalExpense = 0.0;
                for (var doc in allTransactions) {
                  final data = doc.data() as Map<String, dynamic>;
                  final type = data['type'] ?? '';
                  if (type == 'Expense') {
                    final amount = data['amount'] as num? ?? 0;
                    totalExpense += amount.toDouble();
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
                          IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _pickMonth(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Month: ${_selectedMonth.month.toString().padLeft(2, '0')}/${_selectedMonth.year}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Monthly Budget: $currency ${budget.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Remaining: $currency ${remaining.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, color: Colors.green),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Divider(thickness: 1.5, color: Colors.grey),
                    ),
                    Expanded(
                      child: transactions.isEmpty
                          ? Center(child: Text('No transactions found'))
                          : ListView.builder(
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final doc = transactions[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final title = data['title'] ?? 'Untitled';
                                final amount =
                                    (data['amount'] as num?)
                                        ?.toDouble()
                                        .toStringAsFixed(2) ??
                                    '0.00';
                                final date = (data['date'] as Timestamp)
                                    .toDate();
                                final type = data['type'] ?? 'unknown';

                                return Dismissible(
                                  key: Key(doc.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.only(right: 20),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Delete Transaction'),
                                        content: Text(
                                          'Are you sure you want to delete this transaction?',
                                        ),
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

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Transaction deleted'),
                                      ),
                                    );
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
                    ),
                  ],
                );
              },
            ),
    );
  }
}
