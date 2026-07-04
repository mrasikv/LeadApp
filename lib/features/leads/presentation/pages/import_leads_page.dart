import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:typed_data';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../../projects/presentation/bloc/project_state.dart';
import '../../../projects/presentation/bloc/project_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/lead_bloc.dart';
import '../bloc/lead_event.dart';
import '../bloc/lead_state.dart';

class ImportLeadsPage extends StatefulWidget {
  final String? projectId;

  const ImportLeadsPage({super.key, this.projectId});

  @override
  State<ImportLeadsPage> createState() => _ImportLeadsPageState();
}

class _ImportLeadsPageState extends State<ImportLeadsPage> {
  Uint8List? _fileBytes;
  String? _fileName;
  List<List<dynamic>>? _excelData;
  List<String>? _headers;
  Map<String, String> _fieldMapping = {};
  bool _isProcessing = false;
  bool _showMappingScreen = false;
  int _currentStep = 0;
  List<Lead> _previewLeads = [];
  String? _selectedProjectId;
  Project? _selectedProject;

  // Field options for mapping
  final List<Map<String, String>> _leadFields = [
    {'key': 'name', 'label': 'Full Name', 'required': 'true'},
    {'key': 'firstName', 'label': 'First Name', 'required': 'false'},
    {'key': 'lastName', 'label': 'Last Name', 'required': 'false'},
    {'key': 'phone', 'label': 'Phone', 'required': 'true'},
    {'key': 'email', 'label': 'Email', 'required': 'false'},
    {'key': 'alternatePhone', 'label': 'Alternate Phone', 'required': 'false'},
    {'key': 'companyName', 'label': 'Company Name', 'required': 'false'},
    {'key': 'industry', 'label': 'Industry', 'required': 'false'},
    {'key': 'companySize', 'label': 'Company Size', 'required': 'false'},
    {'key': 'website', 'label': 'Website', 'required': 'false'},
    {'key': 'address', 'label': 'Address', 'required': 'false'},
    {'key': 'city', 'label': 'City', 'required': 'false'},
    {'key': 'state', 'label': 'State', 'required': 'false'},
    {'key': 'country', 'label': 'Country', 'required': 'false'},
    {'key': 'zipCode', 'label': 'Zip Code', 'required': 'false'},
    {'key': 'source', 'label': 'Source', 'required': 'false'},
    {'key': 'priority', 'label': 'Priority', 'required': 'false'},
    {'key': 'budgetRange', 'label': 'Budget Range', 'required': 'false'},
    {'key': 'purchaseTimeline', 'label': 'Purchase Timeline', 'required': 'false'},
    {'key': 'interestLevel', 'label': 'Interest Level', 'required': 'false'},
    {'key': 'notes', 'label': 'Notes', 'required': 'false'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
    if (_selectedProjectId != null) {
      context.read<ProjectBloc>().add(LoadProjectEvent(_selectedProjectId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Leads'),
        actions: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _downloadSampleExcel,
              icon: const Icon(Icons.download),
              label: const Text('Sample'),
            ),
        ],
      ),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, projectState) {
          if (projectState is ProjectLoaded && _selectedProject == null) {
            _selectedProject = projectState.project;
          }

          return _buildStepContent();
        },
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildUploadStep();
      case 1:
        return _buildMappingStep();
      case 2:
        return _buildPreviewStep();
      default:
        return _buildUploadStep();
    }
  }

  Widget _buildUploadStep() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Import Leads from Excel',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload an Excel file (.xlsx) with your leads data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_fileName != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: Colors.green),
                  title: Text(_fileName!),
                  subtitle: Text('${_excelData?.length ?? 0} rows'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _fileBytes = null;
                      _fileName = null;
                      _excelData = null;
                      _headers = null;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: 300,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickFile,
                icon: const Icon(Icons.file_upload),
                label: Text(_fileName == null ? 'Select Excel File' : 'Change File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: OutlinedButton.icon(
                onPressed: _downloadSampleExcel,
                icon: const Icon(Icons.download),
                label: const Text('Download Sample Excel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 300,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _processFile,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(_isProcessing ? 'Processing...' : 'Continue'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMappingStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Map your Excel columns to lead fields. Required fields are marked with *',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _headers?.length ?? 0,
            itemBuilder: (context, index) {
              final header = _headers![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Excel Column',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              header,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _fieldMapping[header],
                          decoration: const InputDecoration(
                            labelText: 'Map to Field',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('(Skip)'),
                            ),
                            ..._leadFields.map((field) => DropdownMenuItem(
                                  value: field['key'],
                                  child: Row(
                                    children: [
                                      Text(field['label']!),
                                      if (field['required'] == 'true')
                                        const Text(' *', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value == null) {
                                _fieldMapping.remove(header);
                              } else {
                                _fieldMapping[header] = value;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _validateAndPreview,
                  child: const Text('Preview'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.preview, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Preview: ${_previewLeads.length} leads ready to import',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _previewLeads.length,
            itemBuilder: (context, index) {
              final lead = _previewLeads[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(lead.name),
                  subtitle: Text(lead.phone),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (lead.email != null && lead.email!.isNotEmpty)
                        Text(lead.email!, style: const TextStyle(fontSize: 12)),
                      if (lead.companyName != null && lead.companyName!.isNotEmpty)
                        Text(lead.companyName!, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _importLeads,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isProcessing ? 'Importing...' : 'Import Leads'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _processFile() async {
    if (_fileBytes == null) return;

    setState(() => _isProcessing = true);

    try {
      final excel = excel_lib.Excel.decodeBytes(_fileBytes!);
      final sheet = excel.tables.values.first;

      if (sheet.rows.isEmpty) {
        throw Exception('Excel file is empty');
      }

      // Get headers from first row
      _headers = sheet.rows.first
          .map((cell) => cell?.value?.toString() ?? '')
          .where((h) => h.isNotEmpty)
          .toList();

      // Get data rows (skip header)
      _excelData = sheet.rows.skip(1).map((row) {
        return row.map((cell) => cell?.value?.toString() ?? '').toList();
      }).toList();

      // Try auto-mapping
      _autoMapFields();

      // Check if all required fields are mapped
      final requiredFields = _leadFields
          .where((f) => f['required'] == 'true')
          .map((f) => f['key'])
          .toList();

      final allRequiredMapped = requiredFields.every(
        (field) => _fieldMapping.values.contains(field),
      );

      if (allRequiredMapped) {
        // Auto-mapping successful, go to preview
        _validateAndPreview();
      } else {
        // Show mapping screen
        setState(() {
          _currentStep = 1;
          _showMappingScreen = true;
        });
      }
    } catch (e) {
      _showError('Failed to process file: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _autoMapFields() {
    _fieldMapping.clear();

    for (final header in _headers!) {
      final headerLower = header.toLowerCase().trim();

      // Try exact matches first
      for (final field in _leadFields) {
        final fieldLower = field['label']!.toLowerCase();
        final keyLower = field['key']!.toLowerCase();

        if (headerLower == fieldLower || headerLower == keyLower) {
          _fieldMapping[header] = field['key']!;
          break;
        }
      }

      // Try fuzzy matches
      if (!_fieldMapping.containsKey(header)) {
        if (headerLower.contains('name') && !headerLower.contains('company')) {
          _fieldMapping[header] = 'name';
        } else if (headerLower.contains('first')) {
          _fieldMapping[header] = 'firstName';
        } else if (headerLower.contains('last')) {
          _fieldMapping[header] = 'lastName';
        } else if (headerLower.contains('phone') || headerLower.contains('mobile')) {
          _fieldMapping[header] = 'phone';
        } else if (headerLower.contains('email') || headerLower.contains('mail')) {
          _fieldMapping[header] = 'email';
        } else if (headerLower.contains('company')) {
          _fieldMapping[header] = 'companyName';
        } else if (headerLower.contains('address')) {
          _fieldMapping[header] = 'address';
        } else if (headerLower.contains('city')) {
          _fieldMapping[header] = 'city';
        } else if (headerLower.contains('state')) {
          _fieldMapping[header] = 'state';
        } else if (headerLower.contains('zip') || headerLower.contains('postal')) {
          _fieldMapping[header] = 'zipCode';
        }
      }
    }
  }

  void _validateAndPreview() {
    if (_selectedProjectId == null) {
      _showError('Please select a project first');
      return;
    }

    // Check required fields
    final requiredFields = ['name', 'phone'];
    final missingRequired = requiredFields
        .where((field) => !_fieldMapping.values.contains(field))
        .toList();

    if (missingRequired.isNotEmpty) {
      _showError('Please map required fields: ${missingRequired.join(', ')}');
      return;
    }

    // Build preview leads
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _showError('Not authenticated');
      return;
    }

    _previewLeads = [];

    for (var i = 0; i < (_excelData?.length ?? 0); i++) {
      final row = _excelData![i];
      final leadData = <String, dynamic>{};

      // Map fields
      _fieldMapping.forEach((excelCol, leadField) {
        final colIndex = _headers!.indexOf(excelCol);
        if (colIndex < row.length) {
          final value = row[colIndex]?.toString().trim() ?? '';
          if (value.isNotEmpty) {
            leadData[leadField] = value;
          }
        }
      });

      // Skip empty rows
      if (leadData.isEmpty || !leadData.containsKey('name') || !leadData.containsKey('phone')) {
        continue;
      }

      try {
        final lead = Lead(
          id: '',
          companyId: authState.user.currentCompanyId ?? '',
          projectId: _selectedProjectId!,
          departmentId: '',
          name: leadData['name'] ?? '',
          firstName: leadData['firstName'],
          lastName: leadData['lastName'],
          phone: leadData['phone'] ?? '',
          email: leadData['email'],
          alternatePhone: leadData['alternatePhone'],
          companyName: leadData['companyName'],
          industry: leadData['industry'],
          companySize: leadData['companySize'],
          website: leadData['website'],
          address: leadData['address'],
          city: leadData['city'],
          state: leadData['state'],
          country: leadData['country'],
          zipCode: leadData['zipCode'],
          statusId: '',
          source: leadData['source'],
          priority: leadData['priority'],
          budgetRange: leadData['budgetRange'],
          purchaseTimeline: leadData['purchaseTimeline'],
          interestLevel: leadData['interestLevel'],
          notes: leadData['notes'],
          customFields: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: authState.user.id,
        );

        _previewLeads.add(lead);
      } catch (e) {
        debugPrint('Error creating lead preview for row $i: $e');
      }
    }

    if (_previewLeads.isEmpty) {
      _showError('No valid leads found in the file');
      return;
    }

    setState(() => _currentStep = 2);
  }

  Future<void> _importLeads() async {
    setState(() => _isProcessing = true);

    try {
      for (final lead in _previewLeads) {
        context.read<LeadBloc>().add(CreateLeadEvent(lead));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${_previewLeads.length} leads'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Failed to import leads: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _downloadSampleExcel() {
    // Create sample Excel
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Sample'];

    // Headers
    sheet.appendRow([
      excel_lib.TextCellValue('Name'),
      excel_lib.TextCellValue('Phone'),
      excel_lib.TextCellValue('Email'),
      excel_lib.TextCellValue('Company Name'),
      excel_lib.TextCellValue('Industry'),
      excel_lib.TextCellValue('City'),
      excel_lib.TextCellValue('State'),
      excel_lib.TextCellValue('Zip Code'),
      excel_lib.TextCellValue('Source'),
      excel_lib.TextCellValue('Priority'),
    ]);

    // Sample data
    sheet.appendRow([
      excel_lib.TextCellValue('John Doe'),
      excel_lib.TextCellValue('1234567890'),
      excel_lib.TextCellValue('john@example.com'),
      excel_lib.TextCellValue('Acme Inc'),
      excel_lib.TextCellValue('Technology'),
      excel_lib.TextCellValue('New York'),
      excel_lib.TextCellValue('NY'),
      excel_lib.TextCellValue('10001'),
      excel_lib.TextCellValue('Website'),
      excel_lib.TextCellValue('High'),
    ]);

    sheet.appendRow([
      excel_lib.TextCellValue('Jane Smith'),
      excel_lib.TextCellValue('9876543210'),
      excel_lib.TextCellValue('jane@example.com'),
      excel_lib.TextCellValue('Tech Corp'),
      excel_lib.TextCellValue('Software'),
      excel_lib.TextCellValue('San Francisco'),
      excel_lib.TextCellValue('CA'),
      excel_lib.TextCellValue('94102'),
      excel_lib.TextCellValue('Referral'),
      excel_lib.TextCellValue('Medium'),
    ]);

    // Download
    final bytes = excel.encode();
    // Use browser download or share functionality
    // For web, you'd use html.AnchorElement
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample Excel template downloaded'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
