# Firebase Setup Instructions

This document explains how to complete the Firebase setup for the Kalamy Basil Voice app.

## What's Already Done ✅

1. ✅ Firebase project created (`kalamy-basil-voice`)
2. ✅ Web app registered in Firebase Console
3. ✅ Firebase configuration added to the Flutter app
4. ✅ FirebaseService implemented for synchronization
5. ✅ Security rules created locally

## What You Need to Do

### Step 1: Enable Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **kalamy-basil-voice**
3. Click **Build** → **Firestore Database** in the left sidebar
4. Click **Create database**
5. Select **Start in test mode** (we'll update security rules next)
6. Choose a location (preferably closest to your users, e.g., `us-central1` or `europe-west1`)
7. Click **Enable**

### Step 2: Deploy Firestore Security Rules

Once Firestore is enabled, you need to deploy the security rules:

1. In Firebase Console, go to **Firestore Database**
2. Click on the **Rules** tab
3. Replace the default rules with the content from [`firestore.rules`](firestore.rules):

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is part of the family
    function isValidFamilyCode(familyCode) {
      return familyCode is string && familyCode.size() >= 4;
    }

    // Categories collection
    match /families/{familyCode}/categories/{categoryId} {
      allow read: if isValidFamilyCode(familyCode);
      allow write: if isValidFamilyCode(familyCode);
    }

    // Items collection
    match /families/{familyCode}/items/{itemId} {
      allow read: if isValidFamilyCode(familyCode);
      allow write: if isValidFamilyCode(familyCode);
    }

    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

4. Click **Publish**

### Step 3: Enable Firebase Storage

1. In Firebase Console, go to **Build** → **Storage**
2. Click **Get started**
3. Start in **test mode**
4. Click **Next**
5. Choose the same location as Firestore
6. Click **Done**

### Step 4: Deploy Storage Security Rules

Once Storage is enabled:

1. In Firebase Console, go to **Storage**
2. Click on the **Rules** tab
3. Replace the default rules with the content from [`storage.rules`](storage.rules):

```
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    function isValidFamilyCode(familyCode) {
      return familyCode is string && familyCode.size() >= 4;
    }

    match /families/{familyCode}/images/{imageId} {
      allow read: if isValidFamilyCode(familyCode);
      allow write: if isValidFamilyCode(familyCode)
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

4. Click **Publish**

### Step 5 (Optional): Add Android App

To use the app on Android devices:

1. In Firebase Console, click the gear icon → **Project Settings**
2. Under **Your apps**, click the **Android icon**
3. Register your app with package name: `com.basilworld.kalamy`
4. Download `google-services.json`
5. Place it in `android/app/` directory
6. The FlutterFire configuration is already set up in `lib/firebase_options.dart`

### Step 6 (Optional): Add iOS App

To use the app on iOS devices:

1. In Firebase Console, click the gear icon → **Project Settings**
2. Under **Your apps**, click the **iOS icon**
3. Register your app with bundle ID: `com.basilworld.kalamy`
4. Download `GoogleService-Info.plist`
5. Add it to your Xcode project (in `ios/Runner/`)
6. The FlutterFire configuration is already set up in `lib/firebase_options.dart`

## How Synchronization Works

### Family Code System

- Each family has a unique **Family Code** (4+ digits)
- All data is isolated per family code
- Multiple devices with the same family code share the same data
- Firestore path: `/families/{familyCode}/categories/{categoryId}`
- Storage path: `/families/{familyCode}/images/{imageId}`

### Auto-Sync

The app automatically syncs data when:
- ✅ A family code is entered for the first time
- ✅ A category is added, updated, or deleted
- ✅ An item is added, updated, or deleted
- ✅ App is opened (initial sync on startup)

### Conflict Resolution

When syncing:
1. **Local-first**: App works offline, all data saved locally with Hive
2. **Merge on sync**: Cloud and local data are merged based on `updatedAt` timestamp
3. **Cloud wins**: If timestamps conflict, cloud version takes precedence
4. **Images**: Local images are automatically uploaded to Firebase Storage

### Manual Sync

You can add a sync button in the UI if needed:

```dart
ElevatedButton(
  onPressed: () async {
    await appProvider.syncWithCloud();
  },
  child: Text('Sync Now'),
)
```

## Testing Synchronization

### Test on Multiple Devices

1. **Device 1**:
   - Open the app
   - Enter family code: `1234`
   - Add a new category or item
   - Data is saved locally and synced to cloud

2. **Device 2**:
   - Open the app
   - Enter the same family code: `1234`
   - You should see the category/item from Device 1
   - Any changes on Device 2 will sync back to Device 1

### Verify in Firebase Console

1. Go to **Firestore Database**
2. Navigate to: `families → YOUR_FAMILY_CODE → categories`
3. You should see your categories as documents
4. Navigate to: `families → YOUR_FAMILY_CODE → items`
5. You should see your items as documents

6. Go to **Storage**
7. Navigate to: `families/YOUR_FAMILY_CODE/images/`
8. You should see uploaded images

## Troubleshooting

### Sync not working?

1. Check browser console for errors (F12 → Console)
2. Verify Firestore and Storage are enabled in Firebase Console
3. Verify security rules are published
4. Check if family code is set: `appProvider.getFamilyCode()`

### Permission denied errors?

- Make sure your security rules are published
- Verify the family code is at least 4 characters long
- Check the Firestore/Storage rules match the paths in the code

### Images not uploading?

- Storage only works on actual devices (not web browsers)
- Verify image size is under 5MB
- Check Storage security rules are published

## Firebase Free Tier Limits

Your app uses Firebase's free Spark plan, which includes:

### Firestore Database
- ✅ 1GB storage
- ✅ 50,000 reads/day
- ✅ 20,000 writes/day
- ✅ 20,000 deletes/day

### Cloud Storage
- ✅ 5GB storage
- ✅ 1GB/day downloads
- ✅ 20,000 uploads/day

These limits are more than enough for testing and small-scale use. If you exceed them, you can upgrade to the Blaze (pay-as-you-go) plan.

## Next Steps

After completing the setup:
1. Test the app with a family code
2. Add some categories and items
3. Open the app on another device with the same family code
4. Verify synchronization is working
5. Check Firebase Console to see your data

## Support

If you encounter any issues:
- Check the browser console for error messages
- Review Firebase Console for quota limits
- Check the app logs: `flutter logs`
- Verify your Firebase project settings

---

**Firebase Project**: kalamy-basil-voice
**Project ID**: kalamy-basil-voice
**Project Number**: 170316411027
