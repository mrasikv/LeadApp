import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/utils/status_utils.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../../projects/presentation/bloc/project_event.dart';
import '../../../projects/presentation/bloc/project_state.dart';
import '../bloc/lead_bloc.dart';
import '../bloc/lead_event.dart';
import '../bloc/lead_state.dart';

class LeadDetailPage extends StatefulWidget {
  final String leadId;

  const LeadDetailPage({super.key, required this.leadId});

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<LeadBloc>().add(LoadLeadEvent(widget.leadId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final state = context.read<LeadBloc>().state;
              if (state is LeadLoaded) {
                context.push('/leads/create', extra: state.lead);
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'call',
                child: ListTile(
                  leading: Icon(Icons.phone),
                  title: Text('Call'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'sms',
                child: ListTile(
                  leading: Icon(Icons.message),
                  title: Text('Send SMS'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'email',
                child: ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Send Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'whatsapp',
                child: ListTile(
                  leading: Icon(Icons.chat),
                  title: Text('WhatsApp'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: AppColors.error),
                  title:
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<LeadBloc, LeadState>(
        listener: (context, state) {
          if (state is LeadDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lead deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          } else if (state is LeadUpdated) {
            // Reload lead to show updated data
            context.read<LeadBloc>().add(LoadLeadEvent(widget.leadId));
          } else if (state is LeadLoaded) {
            // Load project to get custom fields
            context
                .read<ProjectBloc>()
                .add(LoadProjectEvent(state.lead.projectId));
          } else if (state is LeadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LeadLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LeadError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(state.error.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<LeadBloc>()
                        .add(LoadLeadEvent(widget.leadId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is LeadLoaded) {
            return _buildLeadDetails(state.lead);
          }

          return const Center(child: Text('Loading lead details...'));
        },
      ),
      bottomNavigationBar: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          if (state is LeadLoaded) {
            return _buildBottomActions(state.lead);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLeadDetails(Lead lead) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lead.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (lead.companyName != null &&
                      lead.companyName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      lead.companyName!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                  if (lead.city != null && lead.city!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      lead.city!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatusChip(lead.statusId),
                      if (lead.priority != null && lead.priority!.isNotEmpty)
                        _buildPriorityChip(lead.priority!),
                      if (lead.interestLevel != null &&
                          lead.interestLevel!.isNotEmpty)
                        _buildInterestChip(lead.interestLevel!),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.phone,
                  label: 'Call',
                  onTap: () => _makePhoneCall(lead.phone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.message,
                  label: 'SMS',
                  onTap: () => _sendSms(lead.phone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.email,
                  label: 'Email',
                  onTap: lead.email != null && lead.email!.isNotEmpty
                      ? () => _sendEmail(lead.email!)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  onTap: () => _openWhatsApp(lead.phone),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact Information
          _buildSection(
            title: 'Contact Information',
            children: [
              if (lead.firstName != null && lead.firstName!.isNotEmpty)
                _buildInfoRow(Icons.person, 'First Name', lead.firstName!),
              if (lead.lastName != null && lead.lastName!.isNotEmpty)
                _buildInfoRow(
                    Icons.person_outline, 'Last Name', lead.lastName!),
              _buildInfoRow(Icons.phone, 'Phone', lead.phone),
              if (lead.alternatePhone != null &&
                  lead.alternatePhone!.isNotEmpty)
                _buildInfoRow(Icons.phone_android, 'Alternate Phone',
                    lead.alternatePhone!),
              if (lead.email != null && lead.email!.isNotEmpty)
                _buildInfoRow(Icons.email, 'Email', lead.email!),
            ],
          ),
          const SizedBox(height: 16),

          // Company Information
          if (lead.companyName != null ||
              lead.industry != null ||
              lead.companySize != null ||
              lead.website != null)
            _buildSection(
              title: 'Company Information',
              children: [
                if (lead.companyName != null && lead.companyName!.isNotEmpty)
                  _buildInfoRow(Icons.business, 'Company', lead.companyName!),
                if (lead.industry != null && lead.industry!.isNotEmpty)
                  _buildInfoRow(Icons.category, 'Industry', lead.industry!),
                if (lead.companySize != null && lead.companySize!.isNotEmpty)
                  _buildInfoRow(
                      Icons.people, 'Company Size', lead.companySize!),
                if (lead.website != null && lead.website!.isNotEmpty)
                  _buildInfoRow(Icons.language, 'Website', lead.website!),
              ],
            ),
          if (lead.companyName != null ||
              lead.industry != null ||
              lead.companySize != null ||
              lead.website != null)
            const SizedBox(height: 16),

          // Address Information
          if (lead.address != null ||
              lead.city != null ||
              lead.state != null ||
              lead.zipCode != null ||
              lead.country != null)
            _buildSection(
              title: 'Address',
              children: [
                if (lead.address != null && lead.address!.isNotEmpty)
                  _buildInfoRow(Icons.location_on, 'Address', lead.address!),
                if (lead.city != null && lead.city!.isNotEmpty)
                  _buildInfoRow(Icons.location_city, 'City', lead.city!),
                if (lead.state != null && lead.state!.isNotEmpty)
                  _buildInfoRow(Icons.map, 'State', lead.state!),
                if (lead.zipCode != null && lead.zipCode!.isNotEmpty)
                  _buildInfoRow(Icons.pin_drop, 'Zip Code', lead.zipCode!),
                if (lead.country != null && lead.country!.isNotEmpty)
                  _buildInfoRow(Icons.flag, 'Country', lead.country!),
              ],
            ),
          if (lead.address != null ||
              lead.city != null ||
              lead.state != null ||
              lead.zipCode != null ||
              lead.country != null)
            const SizedBox(height: 16),

          // Lead Qualification
          if (lead.budgetRange != null ||
              lead.purchaseTimeline != null ||
              lead.priority != null ||
              lead.interestLevel != null)
            _buildSection(
              title: 'Lead Qualification',
              children: [
                if (lead.budgetRange != null && lead.budgetRange!.isNotEmpty)
                  _buildInfoRow(
                      Icons.attach_money, 'Budget Range', lead.budgetRange!),
                if (lead.purchaseTimeline != null &&
                    lead.purchaseTimeline!.isNotEmpty)
                  _buildInfoRow(Icons.schedule, 'Purchase Timeline',
                      lead.purchaseTimeline!),
                if (lead.priority != null && lead.priority!.isNotEmpty)
                  _buildInfoRow(
                      Icons.flag_outlined, 'Priority', lead.priority!),
                if (lead.interestLevel != null &&
                    lead.interestLevel!.isNotEmpty)
                  _buildInfoRow(
                      Icons.star_border, 'Interest Level', lead.interestLevel!),
                _buildInfoRow(Icons.check_circle, 'Decision Maker',
                    lead.isDecisionMaker ?? false ? 'Yes' : 'No'),
              ],
            ),
          if (lead.budgetRange != null ||
              lead.purchaseTimeline != null ||
              lead.priority != null ||
              lead.interestLevel != null)
            const SizedBox(height: 16),

          // Lead Information
          _buildSection(
            title: 'Lead Information',
            children: [
              _buildInfoRow(Icons.source, 'Source', lead.source ?? 'N/A'),
              _buildInfoRow(
                  Icons.calendar_today, 'Created', _formatDate(lead.createdAt)),
              _buildInfoRow(
                  Icons.update, 'Last Updated', _formatDate(lead.updatedAt)),
              if (lead.lastContactedAt != null)
                _buildInfoRow(Icons.call_made, 'Last Contacted',
                    _formatDate(lead.lastContactedAt!)),
              if (lead.nextFollowUpAt != null)
                _buildInfoRow(Icons.event, 'Next Follow-up',
                    _formatDate(lead.nextFollowUpAt!)),
              _buildInfoRow(Icons.phone_in_talk, 'Total Calls',
                  lead.totalCallsCount.toString()),
              _buildInfoRow(
                  Icons.note, 'Total Notes', lead.totalNotesCount.toString()),
            ],
          ),
          const SizedBox(height: 16),

          // Notes Section with Add/Edit capability
          _buildNotesSection(lead),
          const SizedBox(height: 16),

          // Custom Fields Section
          BlocBuilder<ProjectBloc, ProjectState>(
            builder: (context, projectState) {
              if (projectState is ProjectLoaded) {
                return _buildCustomFieldsSection(lead, projectState.project);
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 16),

          // Activity Timeline (placeholder)
          _buildSection(
            title: 'Recent Activity',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.add, color: AppColors.primary, size: 20),
                ),
                title: const Text('Lead Created'),
                subtitle: Text(_formatDate(lead.createdAt)),
              ),
              if (lead.lastContactedAt != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.successLight.withOpacity(0.2),
                    child: const Icon(Icons.phone,
                        color: AppColors.success, size: 20),
                  ),
                  title: const Text('Last Contact'),
                  subtitle: Text(_formatDate(lead.lastContactedAt!)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(Lead lead) {
    final notes = lead.notes ?? lead.customFields['notes'] as String? ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: Icon(notes.isEmpty ? Icons.add : Icons.edit, size: 20),
                  onPressed: () => _showNotesDialog(lead),
                  tooltip: notes.isEmpty ? 'Add notes' : 'Edit notes',
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'No notes yet. Tap + to add notes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNotesDialog(Lead lead) {
    final notesController = TextEditingController(
      text: lead.notes ?? lead.customFields['notes'] as String? ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Add notes about this lead...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    // Try to use notes field, fallback to customFields
                    final newCustomFields =
                        Map<String, dynamic>.from(lead.customFields);
                    newCustomFields['notes'] = notesController.text.trim();

                    final updatedLead = lead.copyWith(
                      notes: notesController.text.trim(),
                      customFields: newCustomFields,
                      updatedAt: DateTime.now(),
                    );
                    context.read<LeadBloc>().add(UpdateLeadEvent(updatedLead));

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notes saved'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    // Reload to reflect changes
                    context.read<LeadBloc>().add(LoadLeadEvent(lead.id));
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFieldsSection(Lead lead, Project project) {
    // Filter out reserved fields (notes, comments)
    final customFields = project.customFields
        .where(
            (field) => field['name'] != 'notes' && field['name'] != 'comments')
        .toList();

    if (customFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Fields',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...customFields.map((field) {
              final fieldName = field['name'] as String;
              final fieldType = field['type'] as String;
              final value = lead.customFields[fieldName]?.toString() ?? '-';

              IconData icon;
              switch (fieldType) {
                case 'number':
                  icon = Icons.numbers;
                  break;
                case 'date':
                  icon = Icons.calendar_today;
                  break;
                case 'checkbox':
                  icon = Icons.check_box;
                  break;
                case 'dropdown':
                  icon = Icons.arrow_drop_down_circle;
                  break;
                default:
                  icon = Icons.text_fields;
              }

              String displayValue = value;
              if (fieldType == 'checkbox') {
                displayValue = value == 'true' ? 'Yes' : 'No';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInfoRow(icon, fieldName, displayValue),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(Lead lead) {
    final comments = (lead.customFields['comments'] as List<dynamic>?) ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments (${comments.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_comment, size: 20),
                  onPressed: () => _showAddCommentDialog(lead),
                  tooltip: 'Add comment',
                ),
              ],
            ),
            if (comments.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'No comments yet. Tap + to add a comment.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final comment = comments[index] as Map<String, dynamic>;
                  final text = comment['text'] as String? ?? '';
                  final author = comment['author'] as String? ?? 'Unknown';
                  final timestamp = comment['timestamp'] as String? ?? '';

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          author.isNotEmpty ? author[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  author,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timestamp,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(text),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: Colors.grey[400]),
                        onPressed: () => _deleteComment(lead, index),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddCommentDialog(Lead lead) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Comment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your comment...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (commentController.text.trim().isEmpty) return;

                  final authState = context.read<AuthBloc>().state;
                  final userName = authState is AuthAuthenticated
                      ? (authState.user.name.isNotEmpty
                          ? authState.user.name
                          : authState.user.email)
                      : 'Unknown';

                  final newComment = {
                    'text': commentController.text.trim(),
                    'author': userName,
                    'timestamp': _formatCommentDate(DateTime.now()),
                    'createdAt': DateTime.now().toIso8601String(),
                  };

                  final existingComments =
                      (lead.customFields['comments'] as List<dynamic>?) ?? [];
                  final newComments = [...existingComments, newComment];

                  final newCustomFields =
                      Map<String, dynamic>.from(lead.customFields);
                  newCustomFields['comments'] = newComments;

                  final updatedLead = lead.copyWith(
                    customFields: newCustomFields,
                    totalNotesCount: newComments.length,
                    updatedAt: DateTime.now(),
                  );
                  context.read<LeadBloc>().add(UpdateLeadEvent(updatedLead));

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment added'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: const Text('Post Comment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteComment(Lead lead, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final existingComments =
                  List<dynamic>.from(lead.customFields['comments'] as List);
              existingComments.removeAt(index);

              final newCustomFields =
                  Map<String, dynamic>.from(lead.customFields);
              newCustomFields['comments'] = existingComments;

              final updatedLead = lead.copyWith(
                customFields: newCustomFields,
                totalNotesCount: existingComments.length,
                updatedAt: DateTime.now(),
              );
              context.read<LeadBloc>().add(UpdateLeadEvent(updatedLead));

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comment deleted'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatCommentDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Material(
      color: onTap != null ? AppColors.primaryContainer : Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon,
                  color: onTap != null ? AppColors.primary : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: onTap != null ? AppColors.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statusId) {
    final color = StatusUtils.getColor(statusId);
    final displayName = StatusUtils.getDisplayName(statusId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'urgent':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInterestChip(String interestLevel) {
    Color color;
    IconData icon;
    switch (interestLevel.toLowerCase()) {
      case 'high':
        color = Colors.green;
        icon = Icons.star;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.star_half;
        break;
      case 'low':
        color = Colors.grey;
        icon = Icons.star_border;
        break;
      default:
        color = Colors.blue;
        icon = Icons.star_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            interestLevel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Lead lead) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showStatusChangeDialog(lead),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change Status'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showFollowUpDialog(lead),
                icon: const Icon(Icons.schedule),
                label: const Text('Schedule Follow-up'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    final state = context.read<LeadBloc>().state;
    if (state is! LeadLoaded) return;
    final lead = state.lead;

    switch (action) {
      case 'call':
        _makePhoneCall(lead.phone);
        break;
      case 'sms':
        _sendSms(lead.phone);
        break;
      case 'email':
        if (lead.email != null) _sendEmail(lead.email!);
        break;
      case 'whatsapp':
        _openWhatsApp(lead.phone);
        break;
      case 'delete':
        _showDeleteDialog(lead);
        break;
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteDialog(Lead lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lead'),
        content: Text('Are you sure you want to delete "${lead.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LeadBloc>().add(DeleteLeadEvent(lead.id));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(Lead lead) {
    final statuses = [
      {'id': 'new', 'name': 'New', 'color': Colors.blue},
      {'id': 'contacted', 'name': 'Contacted', 'color': Colors.orange},
      {'id': 'qualified', 'name': 'Qualified', 'color': Colors.purple},
      {'id': 'proposal', 'name': 'Proposal Sent', 'color': Colors.teal},
      {'id': 'negotiation', 'name': 'Negotiation', 'color': Colors.amber},
      {'id': 'won', 'name': 'Won', 'color': Colors.green},
      {'id': 'lost', 'name': 'Lost', 'color': Colors.red},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Status',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses.map((status) {
                final isSelected =
                    lead.statusId.toLowerCase() == status['id'] ||
                        (lead.statusId.isEmpty && status['id'] == 'new');
                return ChoiceChip(
                  label: Text(status['name'] as String),
                  selected: isSelected,
                  selectedColor: (status['color'] as Color).withOpacity(0.3),
                  onSelected: (selected) {
                    if (selected && !isSelected) {
                      context.read<LeadBloc>().add(
                            ChangeLeadStatusEvent(
                                lead.id, status['id'] as String),
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Status changed to ${status['name']}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      // Reload lead details
                      context.read<LeadBloc>().add(LoadLeadEvent(lead.id));
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFollowUpDialog(Lead lead) {
    DateTime selectedDate = lead.nextFollowUpAt ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schedule Follow-up',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),

              // Quick options
              Text('Quick Options',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Tomorrow'),
                    onPressed: () {
                      setModalState(() {
                        selectedDate =
                            DateTime.now().add(const Duration(days: 1));
                        selectedTime = const TimeOfDay(hour: 10, minute: 0);
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('In 3 days'),
                    onPressed: () {
                      setModalState(() {
                        selectedDate =
                            DateTime.now().add(const Duration(days: 3));
                        selectedTime = const TimeOfDay(hour: 10, minute: 0);
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('Next week'),
                    onPressed: () {
                      setModalState(() {
                        selectedDate =
                            DateTime.now().add(const Duration(days: 7));
                        selectedTime = const TimeOfDay(hour: 10, minute: 0);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
              ),

              // Time picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setModalState(() => selectedTime = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final followUpDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    // Update lead with new follow-up date
                    final updatedLead = lead.copyWith(
                      nextFollowUpAt: followUpDateTime,
                      updatedAt: DateTime.now(),
                    );
                    context.read<LeadBloc>().add(UpdateLeadEvent(updatedLead));

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Follow-up scheduled for ${selectedDate.day}/${selectedDate.month} at ${selectedTime.format(context)}'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Schedule Follow-up'),
                ),
              ),

              // Clear button if already has follow-up
              if (lead.nextFollowUpAt != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      final updatedLead = lead.copyWith(
                        nextFollowUpAt: null,
                        updatedAt: DateTime.now(),
                      );
                      context
                          .read<LeadBloc>()
                          .add(UpdateLeadEvent(updatedLead));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Follow-up cleared'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    },
                    child: const Text('Clear Follow-up'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
