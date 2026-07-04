# 📋 LEADFLOW PRO - USER FLOWS & FEATURES

## Table of Contents

1. [User Roles & Permissions](#user-roles--permissions)
2. [Authentication Flows](#authentication-flows)
3. [User Flows by Role](#user-flows-by-role)
4. [Project & Lead Management](#project--lead-management)
5. [Firestore Data Structure](#firestore-data-structure)
6. [Route Structure](#route-structure)

---

## User Roles & Permissions

### Role Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                       SUPER ADMIN                           │
│  - Global system access                                     │
│  - Manages Project Types (templates)                        │
│  - Manages all Companies                                    │
│  - No companyId (isSuperAdmin = true)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      COMPANY ADMIN                          │
│  - Full access within their company                         │
│  - Manages users, departments, projects                     │
│  - Manages company-specific settings                        │
│  - companyId = specific company                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         MANAGER                             │
│  - Manages team/department leads                            │
│  - Views team analytics                                     │
│  - Assigns leads to team members                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                          AGENT                              │
│  - Works on assigned leads                                  │
│  - Logs calls, updates statuses                             │
│  - Personal dashboard only                                  │
└─────────────────────────────────────────────────────────────┘
```

### Permissions Matrix

| Permission              | Super Admin | Company Admin | Manager | Agent |
| ----------------------- | :---------: | :-----------: | :-----: | :---: |
| Manage Project Types    |     ✅      |      ❌       |   ❌    |  ❌   |
| Manage All Companies    |     ✅      |      ❌       |   ❌    |  ❌   |
| Create/Edit Company     |     ✅      |   Own only    |   ❌    |  ❌   |
| Manage Company Users    |     ✅      |      ✅       |   ❌    |  ❌   |
| Create Projects         |     ✅      |      ✅       |   ✅    |  ❌   |
| Manage Project Statuses |     ✅      |      ✅       |   ✅    |  ❌   |
| View All Leads          |     ✅      |      ✅       |  Team   |  Own  |
| Create/Edit Leads       |     ✅      |      ✅       |   ✅    |  ✅   |
| Assign Leads            |     ✅      |      ✅       |   ✅    |  ❌   |
| View Analytics          |     ✅      |      ✅       |  Team   |  Own  |

---

## Authentication Flows

### Flow 1: Super Admin Login

```
┌─────────────┐    ┌──────────────┐    ┌───────────────────┐
│ Login Page  │───▶│ Firebase Auth│───▶│ Check user doc    │
└─────────────┘    └──────────────┘    └───────────────────┘
                                                │
                                                ▼
                                       ┌───────────────────┐
                                       │ isSuperAdmin=true │
                                       │ companyIds = []   │
                                       └───────────────────┘
                                                │
                                                ▼
                                       ┌───────────────────┐
                                       │ /super-admin      │
                                       │ dashboard         │
                                       └───────────────────┘
```

### Flow 2: Company User Login

```
┌─────────────┐    ┌──────────────┐    ┌───────────────────┐
│ Login Page  │───▶│ Firebase Auth│───▶│ Check user doc    │
└─────────────┘    └──────────────┘    └───────────────────┘
                                                │
                                                ▼
                                       ┌───────────────────┐
                                       │ isSuperAdmin=false│
                                       │ companyIds = [...]│
                                       └───────────────────┘
                                                │
                                                ▼
                                       ┌───────────────────┐
                                       │ Load companies    │
                                       │ Set current       │
                                       └───────────────────┘
                                                │
                                                ▼
                                       ┌───────────────────┐
                                       │ /dashboard        │
                                       └───────────────────┘
```

---

## User Flows by Role

### Super Admin User Flow

```
LOGIN
  │
  ▼
/super-admin/dashboard  ◄─────────────────────────────────────┐
  │                                                           │
  ├──▶ [Project Types Tab]                                    │
  │      │                                                    │
  │      ├──▶ Create Project Type                             │
  │      │      └── Name, Icon, Color, Default Statuses       │
  │      │                                                    │
  │      ├──▶ Edit Project Type                               │
  │      │      └── Modify statuses, toggle active            │
  │      │                                                    │
  │      └──▶ Delete/Deactivate Project Type                  │
  │                                                           │
  ├──▶ [Companies Tab]                                        │
  │      │                                                    │
  │      ├──▶ View All Companies                              │
  │      ├──▶ Create New Company                              │
  │      ├──▶ Edit Company Details                            │
  │      └──▶ Manage Company Admin                            │
  │                                                           │
  └──▶ [Analytics Tab]                                        │
         └── System-wide stats                                │
                                                              │
  Logout ──────────────────────────────────────────────────▶ LOGIN
```

### Company Admin User Flow

```
LOGIN
  │
  ▼
/dashboard  ◄─────────────────────────────────────────────────┐
  │                                                           │
  ├──▶ [Home Tab] - Projects Grid                             │
  │      │                                                    │
  │      ├──▶ View Projects                                   │
  │      │      └── Click project → /projects/:id             │
  │      │                                                    │
  │      └──▶ Create Project (+FAB)                           │
  │             └── Select Project Type                       │
  │             └── Enter Details                             │
  │             └── Auto-create statuses from template        │
  │                                                           │
  ├──▶ [Leads Tab]                                            │
  │      └── View/Filter leads across all projects            │
  │                                                           │
  ├──▶ [Calls Tab]                                            │
  │      └── View call logs                                   │
  │                                                           │
  ├──▶ [Follow-ups Tab]                                       │
  │      └── View scheduled follow-ups                        │
  │                                                           │
  └──▶ [More Tab]                                             │
         │                                                    │
         ├──▶ /company-admin - Admin Dashboard                │
         │      ├── User Management                           │
         │      ├── Status Management                         │
         │      └── Company Settings                          │
         │                                                    │
         ├──▶ /profile - User Profile                         │
         └──▶ Logout                                          │
                                                              │
  Switch Company ─────────────────────────────────────────▶ Reload
```

### Project Detail Flow

```
/projects/:id
  │
  ├──▶ [Leads Tab]
  │      │
  │      ├──▶ View Mode Toggle: Card ↔ List
  │      │
  │      ├──▶ Status Filter Chips
  │      │      └── Filter by project-specific statuses
  │      │
  │      ├──▶ Lead Cards/List
  │      │      └── Click → /leads/:id
  │      │
  │      └──▶ Create Lead (+FAB)
  │             └── /leads/create?projectId=xxx
  │
  └──▶ [Analytics Tab]
         └── Project-specific stats
```

---

## Project & Lead Management

### Project Type (Super Admin Managed)

**Purpose**: Templates that define default statuses for projects

```dart
ProjectType {
  id: String
  name: "Real Estate"
  description: "For property sales leads"
  icon: "home"
  color: "#4CAF50"
  isActive: true
  defaultStatuses: [
    StatusTemplate(name: "New", category: "to_do", color: "#2196F3", order: 1, isDefault: true),
    StatusTemplate(name: "Site Visit", category: "in_progress", color: "#FF9800", order: 2),
    StatusTemplate(name: "Negotiation", category: "in_progress", color: "#9C27B0", order: 3),
    StatusTemplate(name: "Won", category: "done", color: "#4CAF50", order: 4),
    StatusTemplate(name: "Lost", category: "done", color: "#F44336", order: 5),
  ]
}
```

### Project (Company Owned)

**Purpose**: Companies create projects based on project types

```dart
Project {
  id: String
  companyId: String           // Owner company
  name: "Mumbai Q4 2026"
  projectTypeId: String       // Reference to template used
  projectTypeName: String     // Denormalized for display
  icon: String?
  color: String?
  isActive: true
  leadCount: 150
  activeLeadCount: 75
  wonLeadCount: 25
}
```

### Lead Status (Project Specific)

**Purpose**: Each project has its own statuses (created from template)

```dart
LeadStatus {
  id: String
  companyId: String
  projectId: String          // Links to specific project
  name: "Site Visit Scheduled"
  category: "in_progress"    // to_do, in_progress, done
  color: "#FF9800"
  order: 2
  isDefault: false           // Default for new leads
  mandatoryFields: ["appointmentDate", "location"]
}
```

### Lead (Belongs to Project)

```dart
Lead {
  id: String
  companyId: String
  projectId: String          // Required - which project
  departmentId: String
  name: "John Doe"
  phone: "+91-9876543210"
  statusId: String           // Current status
  assignedTo: String?        // User ID
  // ... other fields
}
```

---

## Firestore Data Structure

### Collections

```
firestore
├── users                    # All users (super admin + company users)
│   └── {userId}
│       ├── id
│       ├── email
│       ├── name
│       ├── isSuperAdmin     # true for super admins
│       ├── companyIds[]     # Companies user belongs to
│       ├── currentCompanyId
│       └── ...
│
├── companies
│   └── {companyId}
│       ├── id
│       ├── name
│       ├── code             # Unique company code
│       └── ...
│
├── project_types            # Super Admin managed templates
│   └── {projectTypeId}
│       ├── id
│       ├── name
│       ├── defaultStatuses[]
│       └── ...
│
├── projects                 # Company projects
│   └── {projectId}
│       ├── id
│       ├── companyId        # Owner
│       ├── projectTypeId    # Template used
│       └── ...
│
├── lead_statuses            # Project-specific statuses
│   └── {statusId}
│       ├── id
│       ├── companyId
│       ├── projectId        # Which project (null = company-wide)
│       └── ...
│
├── leads
│   └── {leadId}
│       ├── id
│       ├── companyId
│       ├── projectId        # Required
│       ├── statusId
│       └── ...
│
└── company_users            # User-Company relationship with roles
    └── {companyUserId}
        ├── userId
        ├── companyId
        ├── roleId
        ├── departmentId
        └── permissions[]
```

### Firestore Security Rules Pattern

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Super Admin check
    function isSuperAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperAdmin == true;
    }

    // Company access check
    function belongsToCompany(companyId) {
      return companyId in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.companyIds;
    }

    // Project Types - Super Admin only
    match /project_types/{typeId} {
      allow read: if request.auth != null;
      allow write: if isSuperAdmin();
    }

    // Projects - Company members
    match /projects/{projectId} {
      allow read: if belongsToCompany(resource.data.companyId);
      allow create: if belongsToCompany(request.resource.data.companyId);
      allow update, delete: if belongsToCompany(resource.data.companyId);
    }

    // Leads - Company members
    match /leads/{leadId} {
      allow read, write: if belongsToCompany(resource.data.companyId)
                         || belongsToCompany(request.resource.data.companyId);
    }
  }
}
```

---

## Route Structure

### Public Routes (Unauthenticated)

| Route             | Page              | Description             |
| ----------------- | ----------------- | ----------------------- |
| `/login`          | LoginPage         | Email/password login    |
| `/company-login`  | CompanyLoginPage  | Login with company code |
| `/company-signup` | CompanySignupPage | Register new company    |

### Super Admin Routes

| Route                        | Page                            | Description               |
| ---------------------------- | ------------------------------- | ------------------------- |
| `/super-admin`               | SuperAdminCompanyManagementPage | Manage companies          |
| `/super-admin/dashboard`     | SuperAdminDashboardPage         | Project types & analytics |
| `/super-admin/companies/:id` | CompanyDetailsPage              | Company details           |

### Company User Routes

| Route           | Page           | Description          |
| --------------- | -------------- | -------------------- |
| `/dashboard`    | DashboardPage  | Main home with tabs  |
| `/leads`        | LeadsPage      | All leads list       |
| `/leads/create` | CreateLeadPage | Create new lead      |
| `/leads/:id`    | LeadDetailPage | Lead details         |
| `/calls`        | CallLogsPage   | Call history         |
| `/follow-ups`   | FollowUpsPage  | Scheduled follow-ups |
| `/targets`      | TargetsPage    | Sales targets        |
| `/profile`      | ProfilePage    | User profile         |

### Project Routes

| Route              | Page              | Description               |
| ------------------ | ----------------- | ------------------------- |
| `/projects/create` | CreateProjectPage | Create new project        |
| `/projects/:id`    | ProjectDetailPage | Project detail with leads |

### Company Admin Routes

| Route                     | Page                      | Description     |
| ------------------------- | ------------------------- | --------------- |
| `/company-admin`          | CompanyAdminDashboardPage | Admin panel     |
| `/company-admin/users`    | UserManagementPage        | Manage users    |
| `/company-admin/statuses` | StatusManagementPage      | Manage statuses |

---

## Initial Setup Checklist

### For Super Admin

1. Create Firebase Auth user
2. Create user document with:
   ```json
   {
     "id": "<uid>",
     "email": "admin@leadflow.com",
     "name": "Super Admin",
     "isSuperAdmin": true,
     "companyIds": [],
     "isActive": true
   }
   ```
3. Login → Auto-redirects to `/super-admin`
4. Create Project Types with default statuses

### For Company Admin

1. Super Admin creates company OR user signs up
2. Create user document with:
   ```json
   {
     "id": "<uid>",
     "email": "admin@company.com",
     "name": "Company Admin",
     "isSuperAdmin": false,
     "companyIds": ["<companyId>"],
     "currentCompanyId": "<companyId>",
     "isActive": true
   }
   ```
3. Create company_user document with role
4. Login → Redirects to `/dashboard`
5. Create projects → Auto-creates statuses
6. Add leads to projects

---

## Error Handling

### Common Errors & Solutions

| Error                                 | Cause                      | Solution                               |
| ------------------------------------- | -------------------------- | -------------------------------------- |
| `invalid-argument: empty document ID` | Empty string in companyIds | Filter out empty strings before query  |
| `permission-denied`                   | Firestore rules blocking   | Check user's companyIds match document |
| `Unauthenticated redirect loop`       | Auth state not loaded      | Wait for AuthBloc to emit state        |

---

## Version History

- **v1.0**: Basic lead management
- **v2.0**: Multi-company support
- **v3.0**: Project types and project-specific statuses

---

_Last Updated: January 2026_
