import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddNewPage extends StatefulWidget {
  const AddNewPage({Key? key}) : super(key: key);

  @override
  State<AddNewPage> createState() => _AddNewPageState();
}

class _AddNewPageState extends State<AddNewPage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'Expense';

  Future<void> _saveTransaction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid title and amount.')),
      );
      return;
    }

    // ✅ Prevent future date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (selectedDateOnly.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Date cannot be in the future.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add({
        'title': title,
        'amount': amount,
        'date': Timestamp.fromDate(_selectedDate),
        'type': _transactionType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction added successfully!')),
        );
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add transaction')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // ✅ Prevent future dates
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Description (e.g. Lunch, Salary)'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount (e.g. 100.50)'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Date: ${_selectedDate.toLocal().toIso8601String().split('T').first}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 8),
                TextButton(
                  onPressed: _pickDate,
                  child: Text(
                    'Pick Date',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _transactionType,
              decoration: InputDecoration(labelText: 'Type'),
              items: ['Income', 'Expense'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _transactionType = val!;
                });
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
