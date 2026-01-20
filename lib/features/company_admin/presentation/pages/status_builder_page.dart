import 'package:flutter/material.dart';

class StatusBuilderPage extends StatelessWidget {
  const StatusBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lead Status Builder')),
      body: const Center(child: Text('Customizable Status Pipeline Builder')),
    );
  }
}
