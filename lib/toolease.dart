import 'package:flutter/material.dart';

class Toolease extends StatefulWidget {
  const Toolease({super.key});

  @override
  State<Toolease> createState() => _TooleaseState();
}

class _TooleaseState extends State<Toolease> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: SafeArea(child: Text("Hello World"))),
    );
  }
}
