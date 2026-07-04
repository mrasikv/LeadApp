import 'package:flutter/material.dart';

/// Utility class for mapping status IDs to display names and colors
class StatusUtils {
  // Default status definitions (ID -> Display Name)
  static const Map<String, String> defaultStatusNames = {
    'new': 'New',
    'contacted': 'Contacted',
    'qualified': 'Qualified',
    'proposal': 'Proposal Sent',
    'negotiation': 'Negotiation',
    'won': 'Won',
    'lost': 'Lost',
  };

  // Status colors (hex strings for serialization)
  static const Map<String, String> statusColorHex = {
    'new': '#2196F3', // Blue
    'contacted': '#FF9800', // Orange
    'qualified': '#9C27B0', // Purple
    'proposal': '#009688', // Teal
    'negotiation': '#FFC107', // Amber
    'won': '#4CAF50', // Green
    'lost': '#F44336', // Red
  };

  // Status colors as Color objects
  static const Map<String, Color> statusColors = {
    'new': Colors.blue,
    'contacted': Colors.orange,
    'qualified': Colors.purple,
    'proposal': Colors.teal,
    'negotiation': Colors.amber,
    'won': Colors.green,
    'lost': Colors.red,
  };

  /// Get display name for a status ID
  static String getDisplayName(String statusId) {
    if (statusId.isEmpty) return 'New';
    final id = statusId.toLowerCase();
    return defaultStatusNames[id] ?? _capitalizeFirst(statusId);
  }

  /// Get color for a status ID
  static Color getColor(String statusId) {
    if (statusId.isEmpty) return Colors.blue;
    final id = statusId.toLowerCase();
    return statusColors[id] ?? Colors.grey;
  }

  /// Get color from hex string
  static Color hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Convert Color to hex string
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Capitalize first letter
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Get all default statuses as list of maps (serializable for Firestore)
  static List<Map<String, dynamic>> getDefaultStatuses() {
    return [
      {'id': 'new', 'name': 'New', 'color': '#2196F3', 'order': 1},
      {'id': 'contacted', 'name': 'Contacted', 'color': '#FF9800', 'order': 2},
      {'id': 'qualified', 'name': 'Qualified', 'color': '#9C27B0', 'order': 3},
      {
        'id': 'proposal',
        'name': 'Proposal Sent',
        'color': '#009688',
        'order': 4
      },
      {
        'id': 'negotiation',
        'name': 'Negotiation',
        'color': '#FFC107',
        'order': 5
      },
      {'id': 'won', 'name': 'Won', 'color': '#4CAF50', 'order': 6},
      {'id': 'lost', 'name': 'Lost', 'color': '#F44336', 'order': 7},
    ];
  }
}
