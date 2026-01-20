# Firebase Configuration Guide

## Setup Steps

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Name: "LeadFlow Pro" (or your preference)
4. Enable Google Analytics (recommended)

### 2. Enable Authentication

1. Navigate to Authentication > Sign-in method
2. Enable:
   - Email/Password
   - Phone (for Phase 2)

### 3. Create Firestore Database

1. Navigate to Firestore Database
2. Click "Create Database"
3. Start in **Production Mode**
4. Select region closest to your users

### 4. Deploy Security Rules

```bash
firebase deploy --only firestore:rules
```

### 5. Deploy Indexes

```bash
firebase deploy --only firestore:indexes
```

### 6. Configure Flutter App

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure --project=your-project-id

# Select platforms: Android, iOS
```

This will generate `lib/firebase_options.dart` automatically.

### 7. Enable Cloud Functions (Phase 2)

```bash
firebase init functions
# Select TypeScript
# Install dependencies
```

### 8. Initial Data Seeding

After setup, seed default data:

- Create Super Admin user
- Create system roles
- Create default lead statuses template

## Environment Variables

Create `.env` file:

```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
```

## Testing Firebase Connection

Run the app:

```bash
flutter run
```

Check Firebase connection in logs.

## Cloud Functions (Phase 2)

Functions to create:

1. `onCallLogCreated` - Auto-link to leads
2. `calculateMonthlyTargets` - Aggregate achievements
3. `onLeadStatusChange` - Track time in status
4. `sendNotifications` - Push notifications
5. `enforcePermissions` - Additional validation

## Backup Strategy

Enable automatic backups:

1. Go to Firestore > Settings
2. Enable automatic backups
3. Schedule: Daily at 2 AM UTC
4. Retention: 7 days

## Security Checklist

- ✅ Firestore rules deployed
- ✅ Custom claims configured
- ✅ API keys restricted (Android/iOS)
- ✅ App Check enabled (recommended)
- ✅ Rate limiting configured

## Monitoring

Enable:

1. Firebase Analytics
2. Crashlytics
3. Performance Monitoring
4. Cloud Functions logs

## Cost Optimization

- Enable Firestore caching
- Implement pagination (20 items/page)
- Use composite indexes efficiently
- Monitor read/write operations

## Production Checklist

Before going live:

- [ ] Security rules reviewed
- [ ] Indexes deployed
- [ ] Backup enabled
- [ ] Monitoring configured
- [ ] Rate limits set
- [ ] API keys secured
- [ ] Custom domain configured
- [ ] CORS configured
- [ ] Data retention policies set
