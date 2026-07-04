import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StatusManagementPage extends StatefulWidget {
  const StatusManagementPage({super.key});

  @override
  State<StatusManagementPage> createState() => _StatusManagementPageState();
}

class _StatusManagementPageState extends State<StatusManagementPage> {
  final List<Map<String, dynamic>> _statuses = [
    {
      'id': '1',
      'name': 'New',
      'color': Colors.blue,
      'isDefault': true,
      'order': 1
    },
    {
      'id': '2',
      'name': 'Contacted',
      'color': Colors.orange,
      'isDefault': false,
      'order': 2
    },
    {
      'id': '3',
      'name': 'Qualified',
      'color': Colors.purple,
      'isDefault': false,
      'order': 3
    },
    {
      'id': '4',
      'name': 'Proposal Sent',
      'color': Colors.cyan,
      'isDefault': false,
      'order': 4
    },
    {
      'id': '5',
      'name': 'Negotiation',
      'color': Colors.amber,
      'isDefault': false,
      'order': 5
    },
    {
      'id': '6',
      'name': 'Won',
      'color': Colors.green,
      'isDefault': false,
      'order': 6
    },
    {
      'id': '7',
      'name': 'Lost',
      'color': Colors.red,
      'isDefault': false,
      'order': 7
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStatusDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Status'),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _statuses.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _statuses.removeAt(oldIndex);
            _statuses.insert(newIndex, item);
            // Update order values
            for (int i = 0; i < _statuses.length; i++) {
              _statuses[i]['order'] = i + 1;
            }
          });
        },
        itemBuilder: (context, index) {
          final status = _statuses[index];
          return Card(
            key: ValueKey(status['id']),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.drag_handle, color: Colors.grey),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: status['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              title: Row(
                children: [
                  Text(status['name'] as String),
                  if (status['isDefault'] == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Default',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text('Order: ${status['order']}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleStatusAction(value, status),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (status['isDefault'] != true)
                    const PopupMenuItem(
                      value: 'default',
                      child: ListTile(
                        leading: Icon(Icons.star),
                        title: Text('Set as Default'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (status['isDefault'] != true)
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: AppColors.error),
                        title: Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleStatusAction(String action, Map<String, dynamic> status) {
    switch (action) {
      case 'edit':
        _showEditStatusDialog(status);
        break;
      case 'default':
        setState(() {
          for (var s in _statuses) {
            s['isDefault'] = s['id'] == status['id'];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${status['name']} set as default')),
        );
        break;
      case 'delete':
        _showDeleteDialog(status);
        break;
    }
  }

  void _showAddStatusDialog() {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Status Name'),
              ),
              const SizedBox(height: 16),
              const Text('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.red,
                  Colors.purple,
                  Colors.cyan,
                  Colors.amber,
                  Colors.pink,
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _statuses.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'name': nameController.text,
                      'color': selectedColor,
                      'isDefault': false,
                      'order': _statuses.length + 1,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStatusDialog(Map<String, dynamic> status) {
    final nameController =
        TextEditingController(text: status['name'] as String);
    Color selectedColor = status['color'] as Color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Status Name'),
              ),
              const SizedBox(height: 16),
              const Text('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.red,
                  Colors.purple,
                  Colors.cyan,
                  Colors.amber,
                  Colors.pink,
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    final index =
                        _statuses.indexWhere((s) => s['id'] == status['id']);
                    if (index != -1) {
                      _statuses[index]['name'] = nameController.text;
                      _statuses[index]['color'] = selectedColor;
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: Text(
          'Are you sure you want to delete "${status['name']}"? '
          'Leads with this status will need to be reassigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _statuses.removeWhere((s) => s['id'] == status['id']);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status Management'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Drag and drop to reorder statuses'),
            SizedBox(height: 8),
            Text('• The default status is assigned to new leads'),
            SizedBox(height: 8),
            Text('• You cannot delete the default status'),
            SizedBox(height: 8),
            Text('• Status order affects the sales pipeline view'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
