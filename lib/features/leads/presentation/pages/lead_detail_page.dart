import 'package:flutter/material.dart';

class LeadDetailPage extends StatelessWidget {
  final String leadId;
  
  const LeadDetailPage({super.key, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lead Details')),
      body: Center(child: Text('Lead ID: $leadId')),
    );
  }
}
