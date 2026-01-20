import 'package:flutter/material.dart';

class FormBuilderPage extends StatelessWidget {
  const FormBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Builder')),
      body: const Center(child: Text('Dynamic Form Builder')),
    );
  }
}
