import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/logger_service.dart';

class CompanySignupPage extends StatefulWidget {
  const CompanySignupPage({super.key});

  @override
  State<CompanySignupPage> createState() => _CompanySignupPageState();
}

class _CompanySignupPageState extends State<CompanySignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  String _selectedCompanyType = 'Sales';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _companyTypes = [
    'Sales',
    'Real Estate',
    'Insurance',
    'Financial Services',
    'IT Services',
    'Consulting',
    'Other',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminPhoneController.dispose();
    super.dispose();
  }

  String _generateCompanyCode(String companyName) {
    final name = companyName.trim();
    if (name.isEmpty) return 'COMP00';

    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    String code = '';

    if (words.length >= 2) {
      // Take up to 3 chars from first word and up to 3 from second
      final first = words[0].length >= 3 ? words[0].substring(0, 3) : words[0];
      final second = words[1].length >= 3 ? words[1].substring(0, 3) : words[1];
      code = (first + second).toUpperCase();
    } else {
      // Single word - take up to 6 chars
      code = name.length >= 6
          ? name.substring(0, 6).toUpperCase()
          : name.toUpperCase();
    }

    // Pad to 6 chars minimum
    return code.padRight(6, 'X');
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final firestore = FirebaseFirestore.instance;
    final firebaseAuth = firebase_auth.FirebaseAuth.instance;
    firebase_auth.User? createdUser;

    try {
      // Generate company code
      final companyCode = _generateCompanyCode(_companyNameController.text);

      // 1. First create admin user in Firebase Auth (this authenticates them)
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: _adminEmailController.text.trim(),
        password: _adminPasswordController.text,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user account');
      }

      createdUser = credential.user;
      final adminUserId = createdUser!.uid;
      final now = DateTime.now();

      // 2. Now check if company code already exists (user is authenticated now)
      final existingCompanies = await firestore
          .collection('companies')
          .where('companyCode', isEqualTo: companyCode)
          .get();

      if (existingCompanies.docs.isNotEmpty) {
        // Delete the user we just created since company code exists
        await createdUser.delete();
        throw Exception(
            'Company code already exists. Please choose a different company name.');
      }

      // 3. Create company in Firestore
      final companyDoc = await firestore.collection('companies').add({
        'name': _companyNameController.text.trim(),
        'companyType': _selectedCompanyType,
        'companyCode': companyCode,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'adminUserId': adminUserId,
      });

      final companyId = companyDoc.id;

      // 3. Create user document in Firestore
      final userData = User(
        id: adminUserId,
        email: _adminEmailController.text.trim(),
        name: _adminNameController.text.trim(),
        phone: _adminPhoneController.text.trim().isNotEmpty
            ? _adminPhoneController.text.trim()
            : null,
        isActive: true,
        isSuperAdmin: false,
        createdAt: now,
        updatedAt: now,
        currentCompanyId: companyId,
        currentRoleId: 'company_admin',
        companyIds: [companyId],
        currentPermissions: ['all'],
      );

      await firestore
          .collection('users')
          .doc(adminUserId)
          .set(userData.toJson());

      // 4. Create UserCompany relationship
      await firestore.collection('user_companies').add({
        'userId': adminUserId,
        'companyId': companyId,
        'roleId': 'company_admin',
        'departmentId': null,
        'permissions': ['all'],
        'isActive': true,
        'joinedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Create default lead statuses for the company
      await _createDefaultLeadStatuses(firestore, companyId);

      LoggerService.info(
          'Company created: ${_companyNameController.text} (${companyCode})');

      // Sign out the newly created user (so they can log in fresh)
      await firebaseAuth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Company "${_companyNameController.text}" created successfully! You can now login with your credentials.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );

      // Navigate to login
      context.go('/login');
    } on firebase_auth.FirebaseAuthException catch (e) {
      LoggerService.error('Firebase Auth error during signup', e);
      if (!mounted) return;

      String message = 'Signup failed';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email is already registered';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = e.message ?? 'Signup failed';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      LoggerService.error('Error during company signup', e);

      // Try to clean up the created user if something failed after user creation
      if (createdUser != null) {
        try {
          await createdUser.delete();
          LoggerService.info('Cleaned up partially created user');
        } catch (deleteError) {
          LoggerService.error(
              'Failed to cleanup user after error', deleteError);
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Signup failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createDefaultLeadStatuses(
      FirebaseFirestore firestore, String companyId) async {
    final statuses = [
      {'name': 'New', 'category': 'to_do', 'color': '#2196F3', 'order': 1},
      {
        'name': 'Follow-up',
        'category': 'in_progress',
        'color': '#FF9800',
        'order': 2
      },
      {
        'name': 'Qualified',
        'category': 'in_progress',
        'color': '#4CAF50',
        'order': 3
      },
      {'name': 'Won', 'category': 'done', 'color': '#4CAF50', 'order': 4},
      {'name': 'Lost', 'category': 'done', 'color': '#9E9E9E', 'order': 5},
    ];

    final batch = firestore.batch();

    for (final status in statuses) {
      final docRef = firestore.collection('lead_statuses').doc();
      batch.set(docRef, {
        ...status,
        'id': docRef.id,
        'companyId': companyId,
        'isSystemDefault': true,
        'isActive': true,
        'canDelete': false,
        'mandatoryFields': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Signup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Your Company Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up your organization and admin account',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Company Information Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Company Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                          hintText: 'Enter your company name',
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Company name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Company name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCompanyType,
                        decoration: const InputDecoration(
                          labelText: 'Company Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _companyTypes.map((type) {
                          return DropdownMenuItem(
                              value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCompanyType = value!),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Company code will be automatically generated',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Admin Information Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin User Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminNameController,
                        decoration: const InputDecoration(
                          labelText: 'Admin Name',
                          hintText: 'Enter admin full name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Admin name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Admin Email',
                          hintText: 'admin@company.com',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Admin Phone',
                          hintText: '+1234567890',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Create a strong password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Create Company Account',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
