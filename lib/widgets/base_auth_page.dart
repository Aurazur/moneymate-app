import 'package:flutter/material.dart';

class BaseAuthPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? bottomWidget;

  const BaseAuthPage({
    Key? key,
    required this.title,
    required this.children,
    this.bottomWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/moneymate_logo.jpeg', // Ensure this file exists in assets
                  height: 120,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...children,
                if (bottomWidget != null) ...[
                  const SizedBox(height: 16),
                  bottomWidget!,
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
