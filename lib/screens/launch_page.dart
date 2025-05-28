import 'package:flutter/material.dart';
import 'landing_page.dart';

class LaunchPage extends StatefulWidget {
  @override
  _LaunchPageState createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start fade-in then fade-out animation
    _controller.forward().then((_) {
      _controller.reverse().then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LandingPage()),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 248),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
            'lib/assets/moneymate_logo.png',
            width: 300,
            height: 300,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
