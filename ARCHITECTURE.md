# 🏗️ SYSTEM ARCHITECTURE & DATABASE SCHEMA

## LeadFlow Pro - Enterprise Multi-Tenant CRM

---

## 1. SYSTEM ARCHITECTURE OVERVIEW

### Architecture Pattern: Clean Architecture + MVVM

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Pages   │  │  Widgets │  │   BLoC   │  │   State  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │ Entities │  │ UseCases │  │   Repos  │                  │
│  │  Models  │  │          │  │(Abstract)│                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │   Repos  │  │   Data   │  │ Firebase │                  │
│  │  (Impl)  │  │ Sources  │  │ Services │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

1. **Multi-Tenancy Model**: Company-scoped data isolation
2. **Offline-First**: Firestore caching + Hive for critical data
3. **Permission-Based UI**: Dynamic rendering based on roles
4. **Event Sourcing**: Immutable activity logs for audit trail
5. **Extensible Forms**: JSON-based dynamic form rendering

---

## 2. COMPLETE DATABASE SCHEMA

### Firestore Collections Structure

#### 2.1 Companies Collection

```javascript
companies/{companyId}
{
  id: string,                    // Auto-generated document ID
  name: string,                  // Company name
  companyType: string,           // "Tour Marketing", "Product Sales", etc.
  companyCode: string,           // Unique code for login (e.g., "ABC123")
  logo: string?,                 // Storage URL
  email: string?,
  phone: string?,
  address: string?,
  city: string?,
  state: string?,
  country: string?,
  postalCode: string?,
  website: string?,
  isActive: boolean,             // Active status
  enabledFeatures: {             // Feature toggles
    "leadManagement": true,
    "callLogging": false,        // Phase 2
    "targets": false,            // Phase 2
    "analytics": true,
    "whatsapp": false,           // Phase 3
  },
  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,             // User ID of super admin
}
```

**Indexes:**

- `companyCode` (unique)
- `isActive`

---

#### 2.2 Users Collection

```javascript
users/{userId}
{
  id: string,                    // Firebase Auth UID
  companyId: string,             // Parent company
  email: string,
  name: string,
  phone: string?,
  avatar: string?,               // Storage URL
  roleId: string,                // Reference to roles collection
  departmentId: string?,         // Reference to departments
  permissions: [                 // Derived from role + custom
    "view_leads",
    "create_leads",
    "edit_leads",
    ...
  ],
  isActive: boolean,
  lastLoginAt: timestamp?,
  designation: string?,
  employeeCode: string?,
  customFields: {                // Additional company-specific fields
    "region": "North",
    "team": "Sales A",
  },
  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,
}
```

**Indexes:**

- `companyId + departmentId + isActive`
- `email` (unique)

**Custom Claims (Firebase Auth Token):**

```javascript
{
  companyId: "comp123",
  role: "sales_user",
  permissions: ["view_leads", "create_leads", ...],
}
```

---

#### 2.3 Roles Collection

```javascript
roles/{roleId}
{
  id: string,
  name: string,                  // "Sales User", "Manager", etc.
  companyId: string,             // Empty "" for system roles
  description: string?,
  permissions: [                 // Permission IDs
    "view_leads",
    "create_leads",
    "edit_leads",
    "delete_leads",
    "view_all_leads",
    "export_leads",
    "manage_users",
    "manage_departments",
    "manage_statuses",
    "manage_forms",
    "manage_targets",
    "view_reports",
    "assign_leads",
  ],
  isSystemRole: boolean,         // True for super_admin, etc.
  isActive: boolean,
  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,
}
```

**System Roles (Pre-created):**

- `super_admin` - Full system access
- `company_admin` - Company-wide admin
- `sales_user` - Basic sales user
- `call_agent` - Call center agent
- `manager` - Team manager
- `field_staff` - Field sales

---

#### 2.4 Departments Collection

```javascript
departments/{departmentId}
{
  id: string,
  companyId: string,
  name: string,                  // "Sales", "Support", etc.
  description: string?,
  managerId: string?,            // User ID of manager
  isActive: boolean,
  customFormFields: {            // Additional fields for this dept
    "fieldName": {
      "label": "Project Type",
      "type": "dropdown",
      "options": ["Residential", "Commercial"],
      "required": true,
    },
  },
  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,
}
```

---

#### 2.5 Lead Statuses Collection (Critical - Customizable)

```javascript
lead_statuses/{statusId}
{
  id: string,                    // Immutable UUID (never changes)
  companyId: string,
  name: string,                  // Renameable ("New" → "Incoming Lead")
  category: string,              // "to_do", "in_progress", "done"
  color: string,                 // Hex color "#2196F3"
  order: number,                 // Display order (1, 2, 3, ...)
  isSystemDefault: boolean,      // True for pre-created statuses
  isActive: boolean,
  canDelete: boolean,            // False for system defaults

  // Auto-transition rules
  autoTransitionToStatusId: string?,
  autoTransitionAfterHours: number?,

  // Validation rules
  mandatoryFields: [             // Fields required before entering status
    "phone",
    "email",
    "qualification_notes",
  ],

  // Time tracking
  maxTimeInStatusHours: number?, // Alert if exceeded

  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,
}
```

**Category Enum:**

- `to_do` - Pending action
- `in_progress` - Being worked on
- `done` - Completed (won/lost)

**Default Statuses (System Template):**

```javascript
[
  { name: "New", category: "to_do", order: 1 },
  { name: "Follow-up", category: "in_progress", order: 2 },
  { name: "Recall", category: "in_progress", order: 3 },
  { name: "Qualified", category: "in_progress", order: 4 },
  { name: "Unanswered", category: "to_do", order: 5 },
  { name: "Potential", category: "in_progress", order: 6 },
  { name: "Incoming Call", category: "to_do", order: 7 },
  { name: "Office Visit", category: "in_progress", order: 8 },
  { name: "Won", category: "done", order: 9 },
  { name: "Lost", category: "done", order: 10 },
];
```

**Critical**: Status ID never changes, only name changes. Historical data references ID.

---

#### 2.6 Leads Collection (Core Business Entity)

```javascript
leads/{leadId}
{
  id: string,
  companyId: string,
  departmentId: string,

  // Basic Info
  name: string,
  phone: string,                 // Indexed for call log linking
  email: string?,
  address: string?,
  city: string?,
  state: string?,
  country: string?,

  // Status & Assignment
  statusId: string,              // References lead_statuses.id
  assignedTo: string?,           // User ID
  source: string?,               // "Website", "Referral", etc.

  // Tracking
  lastContactedAt: timestamp?,
  nextFollowUpAt: timestamp?,
  totalCallsCount: number,
  totalNotesCount: number,

  // Custom form data (dynamic)
  customFields: {
    "budget": 50000,
    "property_type": "Apartment",
    "timeline": "3 months",
    ...                          // Company/dept-specific fields
  },

  // Time tracking
  statusChangedAt: timestamp,    // When current status set
  timeInCurrentStatusMinutes: number,

  // Conversion tracking
  isConverted: boolean,
  convertedAt: timestamp?,
  ticketId: string?,             // Reference to ticket/deal

  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,
}
```

**Indexes:**

- `companyId + statusId + createdAt DESC`
- `companyId + assignedTo + updatedAt DESC`
- `companyId + departmentId + createdAt DESC`
- `companyId + phone` (for call linking)

---

#### 2.7 Dynamic Forms Collection

```javascript
dynamic_forms/{formId}
{
  id: string,
  companyId: string,
  departmentId: string?,         // null = company-wide
  name: string,                  // "Lead Capture Form"
  description: string?,
  fields: [
    {
      id: string,
      fieldName: string,         // "budget"
      label: string,             // "Budget Range"
      fieldType: string,         // "text", "number", "dropdown", etc.
      isRequired: boolean,
      isVisible: boolean,
      order: number,
      placeholder: string?,
      defaultValue: string?,

      // Validation
      validationRegex: string?,
      validationMessage: string?,
      minLength: number?,
      maxLength: number?,
      minValue: number?,
      maxValue: number?,

      // Options (for dropdown/multi-select)
      options: ["Option 1", "Option 2", ...],

      // Conditional logic
      dependsOnField: string?,   // Show only if another field has value
      dependsOnValue: any?,
    },
  ],
  isActive: boolean,
  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,
}
```

**Field Types:**

- `text`, `textarea`, `number`, `phone`, `email`, `price`
- `dropdown`, `multi_select`
- `date`, `time`, `datetime`

---

#### 2.8 Activities Collection (Immutable Audit Log)

```javascript
activities/{activityId}
{
  id: string,
  companyId: string,
  leadId: string,
  userId: string,
  activityType: string,          // "status_change", "call", "note", etc.
  description: string,           // Human-readable description

  metadata: {                    // Activity-specific data
    "oldStatus": "New",
    "newStatus": "Follow-up",
    "timeInPreviousStatus": 120, // minutes
    "callDuration": 300,         // seconds (for calls)
  },

  createdAt: timestamp,          // Immutable - no updates
}
```

**Activity Types:**

- `created` - Lead created
- `status_change` - Status updated
- `assignment` - Assigned to user
- `call` - Call made/received
- `note` - Note added
- `updated` - Lead info updated

**Indexes:**

- `companyId + leadId + createdAt DESC`
- `companyId + userId + createdAt DESC`

---

#### 2.9 Notes Collection

```javascript
notes/{noteId}
{
  id: string,
  companyId: string,
  leadId: string,
  content: string,               // Note text
  userId: string?,               // null for system notes
  attachments: [                 // Storage URLs
    "https://storage.../file.pdf",
  ],
  createdAt: timestamp,
  updatedAt: timestamp?,         // Only creator can edit
}
```

---

#### 2.10 Call Logs Collection (Phase 2)

```javascript
call_logs/{callId}
{
  id: string,
  companyId: string,
  userId: string,
  phoneNumber: string,           // Indexed
  callType: string,              // "outgoing", "incoming", "missed"
  duration: number?,             // Seconds (null for missed)
  timestamp: timestamp,

  // Auto-linking
  leadId: string?,               // Auto-matched lead
  isAutoLinked: boolean,

  notes: string?,
  createdAt: timestamp,          // Immutable
}
```

**Indexes:**

- `companyId + userId + timestamp DESC`
- `companyId + phoneNumber + timestamp DESC`

---

#### 2.11 Targets Collection (Phase 2)

```javascript
targets/{targetId}
{
  id: string,
  companyId: string,
  departmentId: string?,         // null = company-wide
  userId: string?,               // null = dept/company target
  targetType: string,            // "price", "quantity", "hybrid"
  month: string,                 // "2026-01" (YYYY-MM)

  // Target values
  targetPrice: number?,
  targetQuantity: number?,

  // Achievement (calculated by Cloud Function)
  achievedPrice: number,
  achievedQuantity: number,
  remainingPrice: number,
  remainingQuantity: number,
  percentageComplete: number,

  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,
}
```

**Indexes:**

- `companyId + userId + month DESC`

---

#### 2.12 Tickets/Deals Collection (Phase 2)

```javascript
tickets/{ticketId}
{
  id: string,
  companyId: string,
  leadId: string,                // Source lead
  name: string,
  userId: string,                // Deal owner

  // Value
  price: number?,
  quantity: number?,
  currency: string?,

  // Status
  status: string,                // "won", "lost", "pending"
  closedAt: timestamp?,
  notes: string?,

  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,
}
```

---

#### 2.13 Audit Logs Collection (Immutable)

```javascript
audit_logs/{logId}
{
  id: string,
  companyId: string,
  userId: string,
  action: string,                // "user_created", "status_deleted", etc.
  resourceType: string,          // "user", "status", "lead", etc.
  resourceId: string,
  details: {                     // JSON metadata
    "changes": { "name": "Old → New" },
  },
  ipAddress: string?,
  userAgent: string?,
  timestamp: timestamp,
}
```

---

## 3. DATA RELATIONSHIPS

```
companies (1) ────┬──── (M) users
                  ├──── (M) departments
                  ├──── (M) lead_statuses
                  ├──── (M) dynamic_forms
                  ├──── (M) leads
                  ├──── (M) targets
                  └──── (M) audit_logs

leads (1) ────┬──── (M) activities
              ├──── (M) notes
              ├──── (M) call_logs
              └──── (1) tickets

users (1) ────┬──── (M) leads (assignedTo)
              ├──── (M) activities
              ├──── (M) call_logs
              └──── (M) targets

lead_statuses (1) ──── (M) leads
departments (1) ──── (M) leads
roles (1) ──── (M) users
```

---

## 4. SECURITY MODEL

### Multi-Tenant Isolation Rules

Every query MUST filter by `companyId`:

```dart
firestore
  .collection('leads')
  .where('companyId', isEqualTo: currentUser.companyId)
```

### Permission Hierarchy

```
Super Admin (Global)
    │
    └─── Company Admin
             │
             ├─── Manager (Department-wide access)
             │      │
             │      └─── Sales User (Own leads only)
             │
             └─── Other Roles
```

### Custom Claims Structure

```javascript
{
  "companyId": "comp_123",
  "role": "sales_user",
  "departmentId": "dept_456",
  "permissions": [
    "view_leads",
    "create_leads",
    "edit_own_leads"
  ]
}
```

---

## 5. SCALABILITY CONSIDERATIONS

### Current Architecture Supports:

- **1,000+ companies** - Company isolation via indexing
- **10,000+ users per company** - Departmental segmentation
- **100,000+ leads per company** - Pagination + indexes
- **Real-time updates** - Firestore streams
- **Offline operation** - Local caching

### Performance Optimizations:

1. **Pagination**: 20 items per page
2. **Composite Indexes**: All filtered queries indexed
3. **Denormalization**: `totalCallsCount`, `totalNotesCount` cached
4. **Aggregation**: Cloud Functions for target calculations
5. **Caching**: Firestore persistence enabled

---

## 6. CLOUD FUNCTIONS (Phase 2)

### Required Functions:

1. **`onUserCreated`** - Set custom claims
2. **`onCallLogCreated`** - Auto-link to leads by phone
3. **`onLeadStatusChange`** - Track time, validate fields
4. **`calculateMonthlyTargets`** - Aggregate achievements
5. **`onLeadConverted`** - Update target progress
6. **`sendNotifications`** - Push notifications
7. **`generateReports`** - Scheduled analytics

---

## 7. MIGRATION & VERSIONING

### Schema Versioning

```javascript
companies/{companyId}
{
  ...
  schemaVersion: 1,             // Track schema version
}
```

### Breaking Changes Strategy

When renaming/removing fields:

1. Keep old field temporarily
2. Migrate data via Cloud Function
3. Update app to use new field
4. Remove old field after 2 app releases

---

**Document Version**: 1.0
**Last Updated**: January 2026
**Maintained By**: Development Team
