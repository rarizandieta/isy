import 'package:flutter/material.dart';

void main() {
  runApp(const IsyApp());
}

class IsyApp extends StatelessWidget {
  const IsyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('Isy')),
      ),
    );
  }
}
