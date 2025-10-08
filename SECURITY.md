# Security Documentation

## Firebase API Key in Public Repository

### ⚠️ GitHub Secret Detection Alert

If you received an email from GitHub about "secrets detected", **don't panic!** This is expected and safe for Firebase web applications.

### Why Firebase Web API Keys Are Public and Safe

The Firebase API key in `lib/firebase_options.dart` and `web/index.html` is **intentionally public**. Here's why:

#### 1. **It's Not a Secret** 🔓
- Firebase web API keys are designed to be included in client-side code
- They're visible in every Firebase web app's source code
- Google's official documentation states: "Unlike how API keys are typically used, API keys for Firebase services are not used to control access to backend resources"

#### 2. **Security is Enforced by Rules** 🔐

Access to your data is controlled by:

**Firestore Security Rules** (`firestore.rules`):
```javascript
// Only users with valid family codes can access their family's data
match /families/{familyCode}/categories/{categoryId} {
  allow read, write: if isValidFamilyCode(familyCode);
}
```

**Storage Security Rules** (`storage.rules`):
```javascript
// Only users with valid family codes can upload images
match /families/{familyCode}/images/{imageId} {
  allow read, write: if isValidFamilyCode(familyCode)
                     && request.resource.size < 5 * 1024 * 1024;
}
```

#### 3. **What the API Key Actually Does** 🔑

The Firebase API key:
- ✅ Identifies which Firebase project to connect to
- ✅ Enables Firebase SDK initialization
- ❌ **Does NOT grant access to data** (security rules do that)
- ❌ **Does NOT allow backend operations** (only client SDK operations)

### Official Google Documentation

From [Firebase Documentation](https://firebase.google.com/docs/projects/api-keys):

> "API keys for Firebase are different from typical API keys: Unlike how API keys are typically used, API keys for Firebase services are not used to control access to backend resources; that can only be done with Firebase Security Rules."

### What Protects Your Data

1. **Family Code System**: Each family's data is isolated by their unique code
2. **Firestore Rules**: Validate family code on every read/write operation
3. **Storage Rules**: Restrict file uploads to images under 5MB
4. **No Authentication Bypass**: Without a valid family code, no data access is possible

### Additional Security Measures (Optional)

If you want additional security layers:

#### Option 1: Firebase App Check
Enable Firebase App Check to verify requests come from your app:
1. Go to Firebase Console → App Check
2. Enable for Web, iOS, and Android
3. Add App Check SDK to your Flutter app

#### Option 2: Domain Restrictions
Restrict your API key to specific domains:
1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Find your Firebase API key
3. Add domain restrictions (e.g., only allow your deployed domain)

#### Option 3: Rotate the API Key
If you're still concerned:
1. Create a new web app in Firebase Console
2. Get the new API key
3. Update `lib/firebase_options.dart` and `web/index.html`
4. Delete the old web app

### Responding to GitHub

You can reply to GitHub's email with:

> "This is a Firebase web API key, which is designed to be public. Security is enforced through Firebase Security Rules, not by keeping the API key secret. See: https://firebase.google.com/docs/projects/api-keys"

Or simply dismiss the alert if GitHub provides that option.

### Best Practices We Follow ✅

- ✅ Firestore Security Rules implemented
- ✅ Storage Security Rules implemented
- ✅ Family Code isolation for data privacy
- ✅ Input validation (family code must be 4+ characters)
- ✅ File size limits (5MB for images)
- ✅ Content type restrictions (only images allowed)
- ✅ No sensitive user data stored
- ✅ Offline-first architecture (data encrypted at rest locally)

### What to Avoid ❌

- ❌ Don't commit Firebase Admin SDK credentials (service account JSON)
- ❌ Don't commit database passwords or private keys
- ❌ Don't commit OAuth client secrets
- ❌ Don't store sensitive user data without encryption

### Real Security Risks (Not Applicable Here)

These would be real security issues:
- 🚨 Firebase Admin SDK service account key in repository
- 🚨 Firebase database with no security rules
- 🚨 API keys for paid services (e.g., Google Maps with billing enabled)
- 🚨 Private encryption keys or certificates

**None of these apply to your Firebase web API key.**

### Summary

✅ **Your Firebase API key in the repository is SAFE**
✅ **Your data is protected by Firestore and Storage Rules**
✅ **The Family Code system provides data isolation**
✅ **This is standard practice for Firebase web/mobile apps**

If you have concerns, deploy the optional security measures above, but the current setup is secure and follows Firebase best practices.

---

## Additional Resources

- [Firebase API Keys Documentation](https://firebase.google.com/docs/projects/api-keys)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Security Best Practices](https://firebase.google.com/support/guides/security-checklist)
- [Stack Overflow: Is it safe to expose Firebase apiKey?](https://stackoverflow.com/questions/37482366/is-it-safe-to-expose-firebase-apikey-to-the-public)

---

**Last Updated**: October 2025
