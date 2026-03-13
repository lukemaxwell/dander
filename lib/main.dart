import 'package:flutter/material.dart';

void main() {
  runApp(const DanderApp());
}

class DanderApp extends StatelessWidget {
  const DanderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Dander',
      home: Scaffold(
        body: Center(child: Text('Dander')),
      ),
    );
  }
}
