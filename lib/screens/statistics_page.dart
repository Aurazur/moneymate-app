import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late List<FinancialData> _chartData;
  late TooltipBehavior _tooltipBehavior;
  final List<String> _filterOptions = [
    'Last 3 Months',
    'Last 6 Months',
    'This Year',
    'Custom Range'
  ];

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
    _loadChartData();
  }

  void _loadChartData() {
    // Sample data - replace with your actual data
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM yyyy');
    
    setState(() {
      _chartData = [
        FinancialData(dateFormat.format(DateTime(now.year, now.month - 5)), 3000, 2500, 5500),
        FinancialData(dateFormat.format(DateTime(now.year, now.month - 4)), 3200, 2700, 5900),
        FinancialData(dateFormat.format(DateTime(now.year, now.month - 3)), 3500, 3000, 6500),
        FinancialData(dateFormat.format(DateTime(now.year, now.month - 2)), 4000, 3200, 7200),
        FinancialData(dateFormat.format(DateTime(now.year, now.month - 1)), 3800, 3100, 6900),
        FinancialData(dateFormat.format(now), 4200, 3500, 7700),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Statistics'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                // Implement actual filtering logic here
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
            // Summary Cards
            Row(
              children: [
                _buildSummaryCard('Total Income', '\$15,700', Colors.green),
                SizedBox(width: 10),
                _buildSummaryCard('Total Expenses', '\$12,300', Colors.red),
                SizedBox(width: 10),
                _buildSummaryCard('Net Savings', '\$3,400', Colors.blue),
              ],
            ),
            SizedBox(height: 20),
            
            // Chart
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
    dataSource: _chartData,
    xValueMapper: (FinancialData data, _) => data.month,
    yValueMapper: (FinancialData data, _) => data.income,
    color: Colors.green[400],
  ),
  ColumnSeries<FinancialData, String>(
    name: 'Expenses',
    dataSource: _chartData,
    xValueMapper: (FinancialData data, _) => data.month,
    yValueMapper: (FinancialData data, _) => data.expenses,
    color: Colors.red[400],
  ),
  LineSeries<FinancialData, String>(
    name: 'Total Budget',
    dataSource: _chartData,
    xValueMapper: (FinancialData data, _) => data.month,
    yValueMapper: (FinancialData data, _) => data.budget,
    color: Colors.blue,
    markerSettings: MarkerSettings(isVisible: true),
  ),
],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Monthly Breakdown
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
                          Text('Income: \$${data.income}'),
                          Text('Expenses: \$${data.expenses}'),
                          Text('Budget: \$${data.budget}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text('\$${data.income - data.expenses}',
                            style: TextStyle(color: Colors.white)),
                        backgroundColor: (data.income - data.expenses) >= 0 
                            ? Colors.green 
                            : Colors.red,
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

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 12)),
              SizedBox(height: 5),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class FinancialData {
  final String month;
  final double income;
  final double expenses;
  final double budget;

  FinancialData(this.month, this.income, this.expenses, this.budget);
}