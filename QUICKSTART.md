# 🚀 QUICK START GUIDE

## Get LeadFlow Pro Running in 30 Minutes

---

## Prerequisites

- ✅ Flutter SDK 3.2+ installed
- ✅ VS Code with Flutter extension
- ✅ Android Studio (for Android development)
- ✅ Xcode (for iOS development on Mac)
- ✅ Firebase account (free tier works)
- ✅ Git installed

---

## Step 1: Clone & Setup (5 minutes)

```bash
# Navigate to project directory
cd e:\myProject\LeadApp

# Install dependencies
flutter pub get

# Generate code (Freezed models)
flutter pub run build_runner build --delete-conflicting-outputs
```

**Expected output**: All dependencies installed, code generation complete.

---

## Step 2: Firebase Setup (10 minutes)

### A. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add Project"**
3. Name: **"LeadFlow Pro"** (or your choice)
4. Enable Google Analytics: **Yes** (recommended)
5. Select/create Analytics account
6. Click **"Create Project"**

### B. Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click **"Get Started"**
3. Select **"Sign-in method"** tab
4. Enable **"Email/Password"**
5. Click **"Save"**

### C. Create Firestore Database

1. Go to **Firestore Database**
2. Click **"Create database"**
3. Select **"Start in production mode"**
4. Choose location closest to your users
5. Click **"Enable"**

### D. Configure Flutter App

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Add to PATH if needed (Windows)
# Add %LOCALAPPDATA%\Pub\Cache\bin to System PATH

# Configure Firebase for this project
flutterfire configure
```

**When prompted:**

- Select your Firebase project: **LeadFlow Pro**
- Select platforms: **Android, iOS** (Space to select, Enter to confirm)
- Overwrite files? **Yes**

**This generates**: `lib/firebase_options.dart`

### E. Deploy Firestore Rules & Indexes

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init firestore

# When prompted:
# - Use existing project: LeadFlow Pro
# - Firestore rules file: firestore.rules (already exists)
# - Firestore indexes file: firestore.indexes.json (already exists)

# Deploy rules and indexes
firebase deploy --only firestore
```

---

## Step 3: Update main.dart (2 minutes)

Open `lib/main.dart` and uncomment Firebase initialization:

```dart
// BEFORE (lines 12-14):
// await Firebase.initializeApp(
//   options: DefaultFirebaseOptions.currentPlatform,
// );

// AFTER:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Step 4: Create First Super Admin (5 minutes)

### Using Firebase Console:

1. Go to **Firebase Console → Authentication**
2. Click **"Add user"**
3. Email: `admin@leadflow.com`
4. Password: `Admin@123` (change later)
5. Click **"Add user"**
6. Copy the generated **User UID**

### Create User Document in Firestore:

1. Go to **Firestore Database**
2. Click **"Start collection"**
3. Collection ID: `users`
4. Document ID: **[Paste the User UID]**
5. Add fields:

```
id: [User UID]
companyId: "" (empty string for super admin)
email: admin@leadflow.com
name: Super Admin
roleId: super_admin
permissions: ["all"] (array)
isActive: true
createdAt: [Current timestamp]
updatedAt: [Current timestamp]
createdBy: system
```

6. Click **"Save"**

### Set Custom Claims:

Create file `scripts/set_admin_claims.js`:

```javascript
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const uid = "YOUR_USER_UID_HERE"; // Replace with actual UID

admin
  .auth()
  .setCustomUserClaims(uid, {
    role: "super_admin",
    companyId: "",
    permissions: ["all"],
  })
  .then(() => {
    console.log("Custom claims set successfully!");
    process.exit();
  });
```

Download service account key from Firebase Console → Project Settings → Service Accounts → Generate new private key.

Run:

```bash
node scripts/set_admin_claims.js
```

---

## Step 5: Run the App (5 minutes)

### Android:

```bash
# List devices
flutter devices

# Run on connected device/emulator
flutter run
```

### iOS (Mac only):

```bash
cd ios
pod install
cd ..
flutter run
```

### Test Login:

1. App should open to login screen
2. Enter:
   - Email: `admin@leadflow.com`
   - Password: `Admin@123`
3. Click **"Login"**
4. Should navigate to dashboard

---

## Step 6: Seed Default Data (5 minutes)

### A. Create Default Lead Statuses

In Firestore, create collection `lead_statuses`:

Use the script at `scripts/seed_data.dart` (create this file):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

Future<void> seedDefaultStatuses(String companyId) async {
  final firestore = FirebaseFirestore.instance;
  final uuid = Uuid();

  final statuses = [
    {'name': 'New', 'category': 'to_do', 'color': '#2196F3', 'order': 1},
    {'name': 'Follow-up', 'category': 'in_progress', 'color': '#FF9800', 'order': 2},
    {'name': 'Recall', 'category': 'in_progress', 'color': '#9C27B0', 'order': 3},
    {'name': 'Qualified', 'category': 'in_progress', 'color': '#4CAF50', 'order': 4},
    {'name': 'Unanswered', 'category': 'to_do', 'color': '#F44336', 'order': 5},
    {'name': 'Potential', 'category': 'in_progress', 'color': '#00BCD4', 'order': 6},
    {'name': 'Incoming Call', 'category': 'to_do', 'color': '#FFC107', 'order': 7},
    {'name': 'Office Visit', 'category': 'in_progress', 'color': '#3F51B5', 'order': 8},
    {'name': 'Won', 'category': 'done', 'color': '#4CAF50', 'order': 9},
    {'name': 'Lost', 'category': 'done', 'color': '#9E9E9E', 'order': 10},
  ];

  for (final status in statuses) {
    await firestore.collection('lead_statuses').add({
      ...status,
      'id': uuid.v4(),
      'companyId': companyId,
      'isSystemDefault': true,
      'isActive': true,
      'canDelete': false,
      'mandatoryFields': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

---

## Troubleshooting

### Issue: "Firebase not initialized"

**Solution**: Make sure you uncommented Firebase initialization in `main.dart` and ran `flutterfire configure`.

### Issue: "Missing firebase_options.dart"

**Solution**: Run `flutterfire configure` again.

### Issue: "Firestore permission denied"

**Solution**: Deploy Firestore rules with `firebase deploy --only firestore:rules`.

### Issue: "Build runner fails"

**Solution**:

```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: "Pod install fails" (iOS)

**Solution**:

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

---

## Next Steps

✅ **You're now ready to develop!**

1. Read `IMPLEMENTATION_GUIDE.md` for next features
2. Start with implementing Lead Repository
3. Then create LeadsBloc
4. Build out Lead management pages

---

## Development Workflow

```bash
# Always run this after modifying models:
flutter pub run build_runner build --delete-conflicting-outputs

# Hot reload during development:
# Press 'r' in terminal where flutter run is active

# Full restart:
# Press 'R' (capital R)

# Check for errors:
flutter analyze
```

---

## Useful Commands

```bash
# Run with specific device
flutter run -d chrome           # Web
flutter run -d android          # Android
flutter run -d ios              # iOS

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Run tests
flutter test

# Generate coverage
flutter test --coverage
```

---

## Resources

- **Firebase Console**: https://console.firebase.google.com
- **Flutter Docs**: https://docs.flutter.dev
- **Project Architecture**: See `ARCHITECTURE.md`
- **Implementation Guide**: See `IMPLEMENTATION_GUIDE.md`

---

## Support

For issues:

1. Check `IMPLEMENTATION_GUIDE.md`
2. Review `ARCHITECTURE.md`
3. Check Firebase logs
4. Review app logs with `flutter logs`

---

**Estimated Setup Time**: 30 minutes
**Next Milestone**: Implement Lead CRUD operations
**Status**: Foundation Complete ✅
