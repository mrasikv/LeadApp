import 'package:flutter/material.dart';

class CreateLeadPage extends StatelessWidget {
  const CreateLeadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Lead')),
      body: const Center(child: Text('Create Lead Form')),
    );
  }
}
