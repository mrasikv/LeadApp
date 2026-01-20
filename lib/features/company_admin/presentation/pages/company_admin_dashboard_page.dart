import 'package:flutter/material.dart';

class CompanyAdminDashboardPage extends StatelessWidget {
  const CompanyAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Admin Dashboard')),
      body: const Center(child: Text('Company Admin Panel')),
    );
  }
}
