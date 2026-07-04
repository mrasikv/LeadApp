import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../../projects/presentation/bloc/project_event.dart';
import '../../../projects/presentation/bloc/project_state.dart';
import '../bloc/lead_bloc.dart';
import '../bloc/lead_event.dart';
import '../bloc/lead_state.dart';

class CreateLeadPageNew extends StatefulWidget {
  final Lead? lead;
  final String? projectId;

  const CreateLeadPageNew({super.key, this.lead, this.projectId});

  @override
  State<CreateLeadPageNew> createState() => _CreateLeadPageNewState();
}

class _CreateLeadPageNewState extends State<CreateLeadPageNew> {
  final _formKey = GlobalKey<FormState>();

  // Contact Details Controllers
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _alternatePhoneController;

  // Company Information Controllers
  late final TextEditingController _companyNameController;
  late final TextEditingController _websiteController;

  // Address Controllers
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _zipCodeController;

  // Notes
  late final TextEditingController _notesController;

  // Custom Fields
  final Map<String, TextEditingController> _customFieldControllers = {};

  // Dropdown Values
  String? _selectedProjectId;
  Project? _selectedProject;
  String _selectedSource = 'Website';
  String? _selectedStatus;
  String? _selectedAssignedTo;
  String _selectedPriority = 'Medium';
  String? _selectedIndustry;
  String? _selectedCompanySize;
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedBudgetRange;
  String? _selectedPurchaseTimeline;
  bool _isDecisionMaker = false;
  String _selectedInterestLevel = 'Medium';

  bool _saveAndCreateNew = false;

  final List<String> _sources = [
    'Website',
    'Referral',
    'Social Media',
    'Cold Call',
    'Email Campaign',
    'Trade Show',
    'Partner',
    'Advertisement',
    'Other',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  final List<String> _industries = [
    'Technology',
    'Healthcare',
    'Finance',
    'Real Estate',
    'Education',
    'Retail',
    'Manufacturing',
    'Automotive',
    'Insurance',
    'Other',
  ];

  final List<String> _companySizes = [
    '1-10',
    '11-50',
    '51-200',
    '201-500',
    '501-1000',
    '1000+',
  ];

  final List<String> _budgetRanges = [
    'Less than \$10K',
    '\$10K - \$50K',
    '\$50K - \$100K',
    '\$100K - \$500K',
    '\$500K+',
  ];

  final List<String> _purchaseTimelines = [
    'Immediate',
    'Within 1 Month',
    '1-3 Months',
    '3-6 Months',
    '6+ Months',
  ];

  final List<String> _interestLevels = ['Low', 'Medium', 'High', 'Hot'];

  bool get _isEditing => widget.lead != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _firstNameController =
        TextEditingController(text: widget.lead?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.lead?.lastName ?? '');
    _emailController = TextEditingController(text: widget.lead?.email ?? '');
    _phoneController = TextEditingController(text: widget.lead?.phone ?? '');
    _alternatePhoneController =
        TextEditingController(text: widget.lead?.alternatePhone ?? '');
    _companyNameController =
        TextEditingController(text: widget.lead?.companyName ?? '');
    _websiteController =
        TextEditingController(text: widget.lead?.website ?? '');
    _addressController =
        TextEditingController(text: widget.lead?.address ?? '');
    _cityController = TextEditingController(text: widget.lead?.city ?? '');
    _zipCodeController =
        TextEditingController(text: widget.lead?.zipCode ?? '');
    _notesController = TextEditingController(
        text: (widget.lead?.customFields['notes'] as String?) ?? '');

    // Initialize dropdown values
    if (widget.lead != null) {
      _selectedSource = widget.lead!.source ?? 'Website';
      _selectedStatus = widget.lead!.statusId;
      _selectedProjectId = widget.lead!.projectId;
      _selectedAssignedTo = widget.lead!.assignedTo;
      _selectedPriority = widget.lead!.priority ?? 'Medium';
      _selectedIndustry = widget.lead!.industry;
      _selectedCompanySize = widget.lead!.companySize;
      _selectedCountry = widget.lead!.country;
      _selectedState = widget.lead!.state;
      _selectedBudgetRange = widget.lead!.budgetRange;
      _selectedPurchaseTimeline = widget.lead!.purchaseTimeline;
      _isDecisionMaker = widget.lead!.isDecisionMaker;
      _selectedInterestLevel = widget.lead!.interestLevel ?? 'Medium';
    } else if (widget.projectId != null) {
      _selectedProjectId = widget.projectId;
    }

    // Load projects
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<ProjectBloc>()
          .add(LoadProjectsEvent(authState.user.currentCompanyId ?? ''));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _companyNameController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _notesController.dispose();
    for (final controller in _customFieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmit({bool createNew = false}) {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final now = DateTime.now();

    // Build full name from first and last name
    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();

    if (_isEditing) {
      // Build custom fields from controllers
      final customFields = Map<String, dynamic>.from(widget.lead!.customFields);
      customFields['notes'] = _notesController.text.trim();
      for (final entry in _customFieldControllers.entries) {
        customFields[entry.key] = entry.value.text.trim();
      }

      final updatedLead = widget.lead!.copyWith(
        name: fullName,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        alternatePhone: _alternatePhoneController.text.trim(),
        companyName: _companyNameController.text.trim(),
        industry: _selectedIndustry,
        companySize: _selectedCompanySize,
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState,
        country: _selectedCountry,
        zipCode: _zipCodeController.text.trim(),
        source: _selectedSource,
        priority: _selectedPriority,
        budgetRange: _selectedBudgetRange,
        purchaseTimeline: _selectedPurchaseTimeline,
        isDecisionMaker: _isDecisionMaker,
        interestLevel: _selectedInterestLevel,
        customFields: customFields,
        updatedAt: now,
      );
      context.read<LeadBloc>().add(UpdateLeadEvent(updatedLead));
    } else {
      // projectId is required for new leads
      if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a project'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Build custom fields from controllers
      final customFields = <String, dynamic>{
        'notes': _notesController.text.trim(),
      };
      for (final entry in _customFieldControllers.entries) {
        customFields[entry.key] = entry.value.text.trim();
      }

      final newLead = Lead(
        id: '', // Will be generated by Firestore
        companyId: authState.user.currentCompanyId ?? '',
        projectId: _selectedProjectId!,
        departmentId: authState.user.currentDepartmentId ?? '',
        name: fullName,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        alternatePhone: _alternatePhoneController.text.trim(),
        companyName: _companyNameController.text.trim(),
        industry: _selectedIndustry,
        companySize: _selectedCompanySize,
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState,
        country: _selectedCountry,
        zipCode: _zipCodeController.text.trim(),
        source: _selectedSource,
        priority: _selectedPriority,
        budgetRange: _selectedBudgetRange,
        purchaseTimeline: _selectedPurchaseTimeline,
        isDecisionMaker: _isDecisionMaker,
        interestLevel: _selectedInterestLevel,
        statusId: _selectedStatus ?? '', // Will be set to default status
        customFields: customFields,
        createdAt: now,
        updatedAt: now,
        createdBy: authState.user.id,
      );

      _saveAndCreateNew = createNew;
      context.read<LeadBloc>().add(CreateLeadEvent(newLead));
    }
  }

  void _initializeCustomFieldControllers(Project project) {
    debugPrint('🔧 Initializing custom fields for: ${project.name}');
    debugPrint('📋 Custom fields RAW: ${project.customFields}');
    debugPrint('📋 Custom fields count: ${project.customFields.length}');
    debugPrint('📋 Custom fields type: ${project.customFields.runtimeType}');

    // Clear existing controllers first
    for (var controller in _customFieldControllers.values) {
      controller.dispose();
    }
    _customFieldControllers.clear();

    for (var i = 0; i < project.customFields.length; i++) {
      final field = project.customFields[i];
      debugPrint('  🔍 Processing field $i: $field');

      if (field is Map<String, dynamic>) {
        final fieldName = field['name'] as String?;
        final fieldType = field['type'] as String?;

        if (fieldName != null && fieldType != null) {
          debugPrint('  ➡️ Field: $fieldName ($fieldType)');

          final existingValue =
              widget.lead?.customFields[fieldName] as String? ?? '';
          _customFieldControllers[fieldName] =
              TextEditingController(text: existingValue);
        } else {
          debugPrint('  ⚠️ Invalid field structure: $field');
        }
      } else {
        debugPrint('  ⚠️ Field is not a Map: ${field.runtimeType}');
      }
    }

    debugPrint(
        '✅ Initialized ${_customFieldControllers.length} custom field controllers');
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<LeadBloc>()),
        BlocProvider(create: (_) => sl<ProjectBloc>()),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: BlocConsumer<LeadBloc, LeadState>(
          listener: (context, state) {
            if (state is LeadCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lead created successfully'),
                  backgroundColor: AppColors.success,
                ),
              );

              if (_saveAndCreateNew) {
                // Reset form
                _formKey.currentState?.reset();
                _firstNameController.clear();
                _lastNameController.clear();
                _emailController.clear();
                _phoneController.clear();
                _alternatePhoneController.clear();
                _companyNameController.clear();
                _websiteController.clear();
                _addressController.clear();
                _cityController.clear();
                _zipCodeController.clear();
                _notesController.clear();
                _customFieldControllers.clear();
                setState(() {
                  _selectedSource = 'Website';
                  _selectedPriority = 'Medium';
                  _selectedInterestLevel = 'Medium';
                  _isDecisionMaker = false;
                  _saveAndCreateNew = false;
                });
              } else {
                context.pop();
              }
            } else if (state is LeadUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lead updated successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.pop();
            } else if (state is LeadError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, leadState) {
            final isLoading = leadState is LeadLoading;

            return BlocBuilder<ProjectBloc, ProjectState>(
              builder: (context, projectState) {
                // Auto-select project if only one available (new lead)
                if (!_isEditing &&
                    _selectedProjectId == null &&
                    projectState is ProjectsLoaded &&
                    projectState.projects.length == 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedProjectId = projectState.projects.first.id;
                      _selectedProject = projectState.projects.first;
                      _initializeCustomFieldControllers(
                          projectState.projects.first);
                    });
                  });
                }

                // Set selected project when editing and projects are loaded
                if (_isEditing &&
                    _selectedProjectId != null &&
                    _selectedProject == null &&
                    projectState is ProjectsLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final project = projectState.projects
                        .where((p) => p.id == _selectedProjectId)
                        .firstOrNull;
                    if (project != null) {
                      setState(() {
                        _selectedProject = project;
                        _initializeCustomFieldControllers(project);
                      });
                    }
                  });
                }

                final customFields = _selectedProject?.customFields ?? [];

                // Debug logging for custom fields
                debugPrint(
                    '🎨 Rendering with custom fields count: ${customFields.length}');
                if (_selectedProject != null) {
                  debugPrint('   Selected project: ${_selectedProject!.name}');
                  debugPrint('   Project ID: ${_selectedProject!.id}');
                  debugPrint('   Custom fields: $customFields');
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Breadcrumb
                      _buildBreadcrumb(),

                      // Form Content
                      Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Section 1: Lead Information
                              _buildSection(
                                title: 'Lead Information',
                                icon: Icons.info_outline,
                                children: [
                                  _buildTwoColumnRow(
                                    left: _buildProjectSelector(
                                        projectState, isLoading),
                                    right: _buildDropdown(
                                      label: 'Lead Source *',
                                      value: _selectedSource,
                                      items: _sources,
                                      onChanged: isLoading
                                          ? null
                                          : (value) => setState(
                                              () => _selectedSource = value!),
                                      icon: Icons.source,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTwoColumnRow(
                                    left: _buildDropdown(
                                      label: 'Priority',
                                      value: _selectedPriority,
                                      items: _priorities,
                                      onChanged: isLoading
                                          ? null
                                          : (value) => setState(
                                              () => _selectedPriority = value!),
                                      icon: Icons.flag_outlined,
                                    ),
                                    right: _buildDropdown(
                                      label: 'Interest Level',
                                      value: _selectedInterestLevel,
                                      items: _interestLevels,
                                      onChanged: isLoading
                                          ? null
                                          : (value) => setState(() =>
                                              _selectedInterestLevel = value!),
                                      icon: Icons.trending_up,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Section 2: Contact Details
                              _buildSection(
                                title: 'Contact Details',
                                icon: Icons.person_outline,
                                children: [
                                  _buildTwoColumnRow(
                                    left: TextFormField(
                                      controller: _firstNameController,
                                      enabled: !isLoading,
                                      decoration: const InputDecoration(
                                        labelText: 'First Name *',
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'First name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    right: TextFormField(
                                      controller: _lastNameController,
                                      enabled: !isLoading,
                                      decoration: const InputDecoration(
                                        labelText: 'Last Name *',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Last name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTwoColumnRow(
                                    left: TextFormField(
                                      controller: _emailController,
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email *',
                                        prefixIcon: Icon(Icons.email),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    right: TextFormField(
                                      controller: _phoneController,
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone',
                                        prefixIcon: Icon(Icons.phone),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _alternatePhoneController,
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Alternate Phone',
                                      prefixIcon: Icon(Icons.phone_android),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Section 3: Company Information
                              _buildSection(
                                title: 'Company Information',
                                icon: Icons.business_outlined,
                                children: [
                                  _buildTwoColumnRow(
                                    left: TextFormField(
                                      controller: _companyNameController,
                                      enabled: !isLoading,
                                      decoration: const InputDecoration(
                                        labelText: 'Company Name *',
                                        prefixIcon: Icon(Icons.business),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Company name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    right: _buildDropdown(
                                      label: 'Industry',
                                      value: _selectedIndustry,
                                      items: _industries,
                                      onChanged: isLoading
                                          ? null
                                          : (value) => setState(
                                              () => _selectedIndustry = value),
                                      icon: Icons.category,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTwoColumnRow(
                                    left: _buildDropdown(
                                      label: 'Company Size',
                                      value: _selectedCompanySize,
                                      items: _companySizes,
                                      onChanged: isLoading
                                          ? null
                                          : (value) => setState(() =>
                                              _selectedCompanySize = value),
                                      icon: Icons.people_outline,
                                    ),
                                    right: TextFormField(
                                      controller: _websiteController,
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.url,
                                      decoration: const InputDecoration(
                                        labelText: 'Website',
                                        prefixIcon: Icon(Icons.language),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Section 4: Address Information
                              _buildSection(
                                title: 'Address Information',
                                icon: Icons.location_on_outlined,
                                children: [
                                  TextFormField(
                                    controller: _addressController,
                                    enabled: !isLoading,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Address',
                                      prefixIcon: Icon(Icons.home),
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTwoColumnRow(
                                    left: TextFormField(
                                      controller: _cityController,
                                      enabled: !isLoading,
                                      decoration: const InputDecoration(
                                        labelText: 'City',
                                        prefixIcon: Icon(Icons.location_city),
                                      ),
                                    ),
                                    right: TextFormField(
                                      controller: _zipCodeController,
                                      enabled: !isLoading,
                                      decoration: const InputDecoration(
                                        labelText: 'Zip Code',
                                        prefixIcon: Icon(Icons.pin_drop),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Section 5: Lead Qualification
                              _buildSection(
                                title: 'Lead Qualification',
                                icon: Icons.assessment_outlined,
                                children: [
                                  _buildTwoColumnRow(
                                    left: _buildDropdown(
                                      label: 'Budget Range',
                                      value: _selectedBudgetRange,
                                      items: _budgetRanges,
                                      onChanged: isLoading
                                          ? null
                                          : (value) => setState(() =>
                                              _selectedBudgetRange = value),
                                      icon: Icons.attach_money,
                                    ),
                                    right: _buildDropdown(
                                      label: 'Purchase Timeline',
                                      value: _selectedPurchaseTimeline,
                                      items: _purchaseTimelines,
                                      onChanged: isLoading
                                          ? null
                                          : (value) => setState(() =>
                                              _selectedPurchaseTimeline =
                                                  value),
                                      icon: Icons.schedule,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CheckboxListTile(
                                    title: const Text('Decision Maker'),
                                    subtitle: const Text(
                                        'Is this person the decision maker?'),
                                    value: _isDecisionMaker,
                                    onChanged: isLoading
                                        ? null
                                        : (value) => setState(() =>
                                            _isDecisionMaker = value ?? false),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Section 6: Custom Fields
                              _buildSection(
                                title: 'Custom Fields',
                                icon: Icons.extension_outlined,
                                children: [
                                  if (customFields.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 20,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'No custom fields defined for this project. Custom fields can be added in project settings.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ...customFields
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final field = entry.value;

                                      debugPrint(
                                          '  🎯 Rendering field $index: ${field['name']}');

                                      // Build rows of two fields
                                      if (index.isEven &&
                                          index + 1 < customFields.length) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: _buildTwoColumnRow(
                                            left: _buildCustomField(
                                                field, isLoading),
                                            right: _buildCustomField(
                                                customFields[index + 1],
                                                isLoading),
                                          ),
                                        );
                                      } else if (index.isOdd) {
                                        // Already handled in even index
                                        return const SizedBox.shrink();
                                      } else {
                                        // Odd number of fields, last one takes full width
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: _buildCustomField(
                                              field, isLoading),
                                        );
                                      }
                                    }),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Section 7: Notes
                              _buildSection(
                                title: 'Notes & Attachments',
                                icon: Icons.note_outlined,
                                children: [
                                  TextFormField(
                                    controller: _notesController,
                                    enabled: !isLoading,
                                    maxLines: 6,
                                    decoration: const InputDecoration(
                                      labelText: 'Notes',
                                      hintText:
                                          'Enter any additional notes about this lead...',
                                      alignLabelWithHint: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Action Buttons
                              _buildActionButtons(isLoading),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isEditing ? 'Edit Lead' : 'Create Lead'),
      elevation: 0,
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.go('/leads'),
            icon: const Icon(Icons.people, size: 16),
            label: const Text('Leads'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
          Icon(Icons.chevron_right,
              size: 16, color: Theme.of(context).dividerColor),
          const SizedBox(width: 4),
          Text(
            _isEditing ? 'Edit' : 'Create',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTwoColumnRow({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          );
        } else {
          return Column(
            children: [
              left,
              const SizedBox(height: 16),
              right,
            ],
          );
        }
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildProjectSelector(ProjectState projectState, bool isLoading) {
    if (projectState is ProjectsLoaded) {
      final projects = projectState.projects;

      if (projects.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.folder_off,
                    size: 48, color: Theme.of(context).disabledColor),
                const SizedBox(height: 8),
                Text(
                  'No projects available',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/projects/create'),
                  child: const Text('Create a project first'),
                ),
              ],
            ),
          ),
        );
      }

      return DropdownButtonFormField<String>(
        value: _selectedProjectId,
        decoration: const InputDecoration(
          labelText: 'Project *',
          prefixIcon: Icon(Icons.folder),
          helperText: 'Select the project for this lead',
        ),
        items: projects.map((project) {
          return DropdownMenuItem(
            value: project.id,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseColor(project.color ?? '#2196F3'),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(project.name)),
              ],
            ),
          );
        }).toList(),
        onChanged: isLoading
            ? null
            : (value) {
                setState(() {
                  _selectedProjectId = value;
                  _selectedProject = projects.firstWhere((p) => p.id == value);
                  _customFieldControllers.clear();
                  _initializeCustomFieldControllers(_selectedProject!);
                });
              },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a project';
          }
          return null;
        },
      );
    }

    if (projectState is ProjectLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCustomField(Map<String, dynamic> field, bool isLoading) {
    final fieldName = field['name'] as String;
    final fieldType = field['type'] as String;
    final isRequired = field['required'] as bool? ?? false;

    if (!_customFieldControllers.containsKey(fieldName)) {
      final existingValue = _isEditing
          ? widget.lead?.customFields[fieldName] as String? ?? ''
          : '';
      _customFieldControllers[fieldName] =
          TextEditingController(text: existingValue);
    }

    final controller = _customFieldControllers[fieldName]!;

    Widget inputWidget;
    switch (fieldType) {
      case 'number':
        inputWidget = TextFormField(
          controller: controller,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '${fieldName}${isRequired ? ' *' : ''}',
            prefixIcon: const Icon(Icons.numbers),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$fieldName is required';
                  }
                  return null;
                }
              : null,
        );
        break;
      case 'date':
        inputWidget = TextFormField(
          controller: controller,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: '${fieldName}${isRequired ? ' *' : ''}',
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: isLoading
                  ? null
                  : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        controller.text =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      }
                    },
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$fieldName is required';
                  }
                  return null;
                }
              : null,
        );
        break;
      case 'checkbox':
        inputWidget = CheckboxListTile(
          title: Text(fieldName),
          value: controller.text.toLowerCase() == 'true',
          onChanged: isLoading
              ? null
              : (value) {
                  setState(() {
                    controller.text = value.toString();
                  });
                },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
        break;
      default:
        inputWidget = TextFormField(
          controller: controller,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: '${fieldName}${isRequired ? ' *' : ''}',
            prefixIcon: const Icon(Icons.edit),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$fieldName is required';
                  }
                  return null;
                }
              : null,
        );
    }

    return inputWidget;
  }

  Widget _buildActionButtons(bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 12,
        children: [
          // Cancel Button
          OutlinedButton(
            onPressed: isLoading ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('Cancel'),
          ),

          if (!_isEditing)
            // Save & Create New Button
            ElevatedButton.icon(
              onPressed:
                  isLoading ? null : () => _handleSubmit(createNew: true),
              icon: const Icon(Icons.add),
              label: const Text('Save & Create New'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                backgroundColor: AppColors.secondary,
              ),
            ),

          // Save Button (Primary)
          ElevatedButton(
            onPressed: isLoading ? null : () => _handleSubmit(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Text(_isEditing ? 'Update Lead' : 'Save Lead'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}
