import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<FinancialData> _chartData = [];
  late TooltipBehavior _tooltipBehavior;
  final List<String> _filterOptions = [
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
    'This Year',
  ];
  String _selectedFilter = 'Last 3 Months';

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
    _loadChartData();
  }

  void _loadChartData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final uid = currentUser.uid;
    final now = DateTime.now();

    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .get();

    Map<String, double> incomeByMonth = {};
    Map<String, double> expenseByMonth = {};

    for (final doc in transactionsSnapshot.docs) {
      final data = doc.data();
      final type = data['type'];
      final amount = (data['amount'] ?? 0).toDouble();
      final timestamp = data['date'];
      final date = (timestamp is Timestamp) ? timestamp.toDate() : DateTime.now();
      final monthKey = DateFormat('MMM yyyy').format(date);

      if (type == 'Income') {
        incomeByMonth[monthKey] = (incomeByMonth[monthKey] ?? 0) + amount;
      } else if (type == 'Expense') {
        expenseByMonth[monthKey] = (expenseByMonth[monthKey] ?? 0) + amount;
      }
    }

    final allMonths = {...incomeByMonth.keys, ...expenseByMonth.keys}.toList()
      ..sort((a, b) => DateFormat('MMM yyyy')
          .parse(b)
          .compareTo(DateFormat('MMM yyyy').parse(a)));
    final chartData = allMonths.map((month) {
      return FinancialData(
        month,
        incomeByMonth[month] ?? 0,
        expenseByMonth[month] ?? 0,
      );
    }).toList();

    setState(() {
      _chartData = chartData;
    });
  }

  List<FinancialData> _filterChartData(String filter) {
    final now = DateTime.now();
    int months = switch (filter) {
      'Last Month' => 1,
      'Last 3 Months' => 3,
      'Last 6 Months' => 6,
      'This Year' => 12,
      _ => 3,
    };
    final cutoff = DateTime(now.year, now.month - months + 1);
    return _chartData.where((data) {
      final date = DateFormat('MMM yyyy').parse(data.month);
      return date.isAfter(cutoff.subtract(Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _filterChartData(_selectedFilter);

    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Statistics'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _filterOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Income vs Expenses'),
                    legend: Legend(isVisible: true),
                    tooltipBehavior: _tooltipBehavior,
                    primaryXAxis: CategoryAxis(),
                    series: <CartesianSeries<FinancialData, String>>[
                      ColumnSeries<FinancialData, String>(
                        name: 'Income',
                        dataSource: filteredData,
                        xValueMapper: (FinancialData data, _) => data.month,
                        yValueMapper: (FinancialData data, _) => data.income,
                        color: Colors.green[400],
                      ),
                      ColumnSeries<FinancialData, String>(
                        name: 'Expenses',
                        dataSource: filteredData,
                        xValueMapper: (FinancialData data, _) => data.month,
                        yValueMapper: (FinancialData data, _) => data.expenses,
                        color: Colors.red[400],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Monthly Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _chartData.length,
                itemBuilder: (context, index) {
                  final data = _chartData[index];
                  return Card(
                    child: ListTile(
                      title: Text(data.month),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Income: \$${data.income.toStringAsFixed(2)}'),
                          Text('Expenses: \$${data.expenses.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          '\$${(data.income - data.expenses).toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor:
                            (data.income - data.expenses) >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialData {
  final String month;
  final double income;
  final double expenses;

  FinancialData(this.month, this.income, this.expenses);
}
