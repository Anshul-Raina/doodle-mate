# Firebase Setup Guide for DoodleMate

This guide will help you set up Firebase for your DoodleMate app.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `doodlemate-[your-name]`
4. Continue through the setup steps

## Step 2: Enable Realtime Database

1. In your Firebase project, go to "Realtime Database"
2. Click "Create Database"
3. Choose "Start in test mode" for now
4. Select a location close to your users

## Step 3: Add Your App

### For Web
1. Click the web icon (</>) in Project Overview
2. Register app with nickname: "DoodleMate Web"
3. Copy the config object

### For Android
1. Click the Android icon in Project Overview
2. Register app with package name: `com.example.doodle_mate`
3. Download `google-services.json`
4. Place it in `android/app/` directory

### For iOS
1. Click the iOS icon in Project Overview
2. Register app with bundle ID: `com.example.doodleMate`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

## Step 4: Update Configuration

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-actual-web-api-key',
  appId: 'your-actual-web-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  authDomain: 'your-actual-project-id.firebaseapp.com',
  databaseURL: 'https://your-actual-project-id-default-rtdb.firebaseio.com',
  storageBucket: 'your-actual-project-id.appspot.com',
);
```

## Step 5: Set Database Rules

In Firebase Console > Realtime Database > Rules, replace the rules with:

```json
{
  "rules": {
    "sessions": {
      "$sessionId": {
        ".read": true,
        ".write": true,
        "strokes": {
          "$strokeId": {
            ".validate": "newData.hasChildren(['id', 'userId', 'color', 'width', 'points', 'timestamp'])"
          }
        },
        ".indexOn": ["lastActivity", "createdAt"]
      }
    }
  }
}
```

## Step 6: Optional - Set up Cleanup Function

For automatic 7-day cleanup, deploy this Cloud Function:

1. Install Firebase CLI: `npm install -g firebase-tools`
2. In your project root: `firebase init functions`
3. Replace `functions/index.js` with the code from `lib/services/cleanup_service.dart`
4. Deploy: `firebase deploy --only functions`

## Testing

1. Run `flutter pub get`
2. Run `flutter run`
3. Test creating and joining sessions
4. Check Firebase Console to see data being written

## Troubleshooting

- **Connection issues**: Check your internet and Firebase project status
- **Permission errors**: Verify database rules are set correctly
- **Build errors**: Ensure all config files are in the right locations
- **Data not syncing**: Check Firebase project ID in configuration

## Security Note

The current rules allow public read/write access for simplicity. For production, consider implementing authentication and more restrictive rules.