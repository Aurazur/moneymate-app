import 'package:flutter/material.dart';

class ConsultantMainPage extends StatelessWidget {
  const ConsultantMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultant Dashboard')),
      body: const Center(child: Text('Consultant Main Page')),
    );
  }
}
