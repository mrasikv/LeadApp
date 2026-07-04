/// Sample Custom Fields for Testing
///
/// To add these to a project in Firebase, run this in your project setup:
///
/// 1. Go to Firebase Console > Firestore
/// 2. Find a project document
/// 3. Add a field called 'customFields' (type: array)
/// 4. Add these objects to the array:

const List<Map<String, dynamic>> sampleCustomFields = [
  {
    'name': 'Lead Source',
    'type': 'text',
    'required': true,
  },
  {
    'name': 'Expected Revenue',
    'type': 'number',
    'required': false,
  },
  {
    'name': 'Follow-up Date',
    'type': 'date',
    'required': false,
  },
  {
    'name': 'Qualified',
    'type': 'checkbox',
    'required': false,
  },
  {
    'name': 'Product Interest',
    'type': 'text',
    'required': false,
  },
  {
    'name': 'Contact Method',
    'type': 'text',
    'required': true,
  },
];

/// Example Firebase console JSON for copy-paste:
///
/// [
///   {"name": "Lead Source", "type": "text", "required": true},
///   {"name": "Expected Revenue", "type": "number", "required": false},
///   {"name": "Follow-up Date", "type": "date", "required": false},
///   {"name": "Qualified", "type": "checkbox", "required": false},
///   {"name": "Product Interest", "type": "text", "required": false},
///   {"name": "Contact Method", "type": "text", "required": true}
/// ]
