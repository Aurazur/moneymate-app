import 'package:flutter/material.dart';
import 'admin_main_page.dart';        // Admin dashboard page
import 'admin_addnew.dart';          // Your AddUserPage here renamed as AdminAddNewPage
import 'admin_profile.dart';         // AdminProfilePage

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({Key? key}) : super(key: key);

  @override
  _AdminScaffoldState createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    AdminMainPage(),
    AdminAddNewPage(),
    AdminProfilePage(),
  ];

  static const List<String> _pageTitles = [
    'Dashboard',
    'Add New User',
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
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 4.0),
              child: Image.asset(
                'lib/assets/moneymate_logo.png',
                width: 64,
                height: 64,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
              ),
            ),
            Text(
              _pageTitles[_selectedIndex],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black,
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
            icon: Icon(Icons.person_add),
            label: 'Add User',
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
