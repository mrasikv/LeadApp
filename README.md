# Lead Management SaaS - Enterprise Multi-Tenant CRM

A production-ready, scalable Flutter + Firebase Lead & Sales Management System for marketing and tour-marketing companies.

## 🏗️ Architecture

- **Clean Architecture** with strict layer separation
- **MVVM + Repository Pattern**
- **Multi-tenant** with company isolation
- **Offline-first** with Firestore caching
- **Role-based permission engine**

## 📦 Tech Stack

- Flutter 3.x (Material 3)
- Firebase (Auth, Firestore, Cloud Functions, FCM)
- BLoC for state management
- GetIt for dependency injection
- GoRouter for navigation

## 🚀 Features

### Phase 1 (Current)

- ✅ Multi-tenant architecture
- ✅ Role-based authentication (Super Admin, Company Admin, Users)
- ✅ Customizable lead status pipelines (To Do, In Progress, Done)
- ✅ Dynamic form builder
- ✅ Daily activity dashboard
- ✅ Lead management with audit trails
- ✅ Department & user management
- ✅ Permission engine

### Phase 2 (Upcoming)

- 📞 Call log integration (Android/iOS)
- 🎯 Target & achievement tracking
- 📊 Advanced analytics
- 🔔 Push notifications

### Phase 3 (Future)

- 💬 WhatsApp integration
- 🤖 AI lead scoring
- 💰 Payment tracking
- 📈 Voice analytics

## 📁 Project Structure

```
lib/
├── core/                    # Core utilities, constants, themes
│   ├── config/             # App configuration
│   ├── constants/          # App constants
│   ├── di/                 # Dependency injection
│   ├── error/              # Error handling
│   ├── network/            # Network layer
│   ├── theme/              # App themes
│   └── utils/              # Utilities
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── super_admin/       # Super admin panel
│   ├── company_admin/     # Company admin panel
│   ├── leads/             # Lead management
│   ├── dashboard/         # Analytics dashboard
│   ├── calls/             # Call log (Phase 2)
│   └── targets/           # Target tracking (Phase 2)
└── main.dart              # Entry point
```

## 🔧 Setup Instructions

### Prerequisites

- Flutter SDK >=3.2.0
- Firebase Project
- VS Code / Android Studio

### Installation

1. Clone the repository

```bash
git clone <repository-url>
cd LeadApp
```

2. Install dependencies

```bash
flutter pub get
```

3. Configure Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

4. **Run code generation** (Required after cloning)

```bash
# Generate Freezed models, JSON serialization, and DI config
dart run build_runner build --delete-conflicting-outputs
```

> ⚠️ **Important**: You must run code generation before building the app. Generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`) are not committed to the repository.

5. Run the app

```bash
# Run on connected device
flutter run

# Run on specific platform
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS
flutter run -d windows   # Windows
```

### Development Workflow

```bash
# Watch mode - auto-regenerate on file changes (recommended during development)
dart run build_runner watch --delete-conflicting-outputs

# One-time generation
dart run build_runner build --delete-conflicting-outputs

# Clean and regenerate (if you encounter issues)
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## 🔐 Security

- Firestore security rules enforcing multi-tenancy
- Role-based access control (RBAC)
- Custom claims for authorization
- Company-scoped data isolation

## 📊 Data Model

### Key Collections

- `companies` - Company profiles
- `users` - User accounts with roles
- `roles` - Role definitions with permissions
- `departments` - Department structure
- `leads` - Lead records
- `lead_statuses` - Customizable status pipelines
- `dynamic_forms` - Form configurations
- `activities` - Audit trail
- `call_logs` - Call history (Phase 2)
- `targets` - Sales targets (Phase 2)

## 🎨 Design System

- **Primary**: Blue (#2196F3) - Trust, professionalism
- **Secondary**: Orange (#FF9800) - Energy, action
- **Success**: Green (#4CAF50)
- **Warning**: Amber (#FFC107)
- **Error**: Red (#F44336)
- **Typography**: Inter font family
- **Material 3** design language

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- 🔄 Web (planned)

## 📄 License

Proprietary - All rights reserved

## 👥 Team

Enterprise SaaS Development Team

---

**Version**: 1.0.0  
**Last Updated**: January 2026
