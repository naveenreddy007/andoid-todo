import 'package:flutter/material.dart';

class ArchivedNotesScreen extends StatelessWidget {
  const ArchivedNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Notes')),
      body: const Center(child: Text('Archived Notes Screen')),
    );
  }
}
