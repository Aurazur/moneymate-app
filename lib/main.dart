import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/launch_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: LaunchPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) => MainScaffold(),
      },
    );
  }
}
