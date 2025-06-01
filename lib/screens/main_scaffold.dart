import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'statistics_page.dart';
import 'addnew_page.dart';
import 'premium_page.dart';
import 'dashboard_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    DashboardPage(),
    StatisticsPage(),
    AddNewPage(),
    PremiumPage(),
    ProfilePage(),
  ];

  static const List<String> _pageTitles = [
    'Dashboard',
    'Statistics',
    'Add Transaction',
    'Premium',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 4.0),
              child: Image.asset(
                'lib/assets/moneymate_logo.png',
                width: 64,
                height: 64,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error);
                },
              ),
            ),
            Text(
              _pageTitles[_selectedIndex],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 232, 240, 239),
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add New',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Premium',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
