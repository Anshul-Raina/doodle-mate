# Getting Started with DoodleMate

Welcome to DoodleMate! This guide will help you get the app running quickly.

## Quick Start (5 minutes)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Test Without Firebase (Local Only)
You can test the basic drawing functionality without setting up Firebase:

1. Comment out Firebase initialization in `lib/main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(const DoodleMateApp());
}
```

2. Run the app:
```bash
flutter run
```

3. You'll be able to draw locally, but collaboration features won't work.

### 3. Set Up Firebase (For Full Features)
For collaborative drawing, follow the [Firebase Setup Guide](FIREBASE_SETUP.md).

## App Features

### ✅ Working Without Firebase
- Solo drawing
- Color picker
- Brush size adjustment
- Undo functionality
- Clear canvas
- Export drawings as PNG

### 🔥 Requires Firebase
- Create collaborative sessions
- Join existing sessions  
- Real-time multi-user drawing
- Cross-device synchronization
- Automatic session cleanup

## Platform Support

- ✅ **Android**: Fully supported
- ✅ **iOS**: Fully supported  
- ✅ **Web**: Fully supported
- ❌ **Desktop**: Not tested (but should work)

## Development Tips

### Hot Reload
The app supports Flutter's hot reload for quick development:
- Save files to see changes instantly
- Drawing state is preserved during hot reload

### Testing
```bash
# Run tests
flutter test

# Run on different platforms
flutter run -d chrome        # Web
flutter run -d ios           # iOS Simulator  
flutter run -d android       # Android Emulator
```

### Building for Release
```bash
# Android APK
flutter build apk --release

# iOS App
flutter build ios --release

# Web
flutter build web --release
```

## Common Issues

### 1. Firebase Connection Errors
- Check your `firebase_options.dart` configuration
- Verify Firebase project settings
- Ensure internet connectivity

### 2. Drawing Not Smooth
- This might happen on slower devices
- The app is optimized for 60fps on most modern devices

### 3. Export Not Working
- Ensure write permissions on device
- Check available storage space

### 4. Session Not Found
- Session IDs are case-sensitive
- Sessions expire after 7 days of inactivity

## Next Steps

1. **Customize Colors**: Add more color presets in `drawing_screen.dart`
2. **Add Shapes**: Extend the drawing tools with shapes like circles, rectangles
3. **User Avatars**: Add user identification in collaborative sessions
4. **Chat**: Add a simple chat feature for collaborators
5. **Layers**: Implement drawing layers for more complex artwork

## Contributing

Found a bug or want to add a feature? Check out our [Contributing Guide](README.md#contributing).

## Support

- 📧 Create an issue on GitHub
- 📱 Test on multiple devices
- 🔄 Keep the app updated

Happy drawing! 🎨