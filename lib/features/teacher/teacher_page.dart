import 'package:flutter/material.dart';

class TeacherPage extends StatelessWidget {
  const TeacherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Page')),
      body: const Center(child: Text('Welcome, Teacher!')),
    );
  }
}