# Reflector - Video Journal App

A Flutter app for recording and managing personal video journals.

## Features

- **Video Recording**: Record videos with front camera priority
- **Video Gallery**: Browse and manage recorded videos
- **Video Playback**: YouTube-style video player with controls
- **Thumbnail Generation**: Automatic thumbnail generation for videos
- **Duration Display**: Show video duration in gallery
- **Save to Gallery**: Save videos to device's photo gallery
- **Persistent Storage**: Videos and database survive app updates

## Data Persistence

The app uses persistent storage that survives app updates and reinstalls:

### Storage Locations
- **Database**: `Documents/video_journal.db` (persistent)
- **Videos**: `Documents/videos/` (persistent)
- **Thumbnails**: `Documents/thumbnails/` (persistent)

### Why Videos Persist
- Uses `getApplicationDocumentsDirectory()` instead of temporary directories
- Database and files stored in app's documents folder
- Documents folder survives app updates and hot reloads
- Automatic cleanup of orphaned database entries

### Debug Information
The app logs detailed information about:
- Database path location
- Number of videos found in database
- File existence checks for videos and thumbnails
- Orphaned entry cleanup

## Development

### Permissions Required
- Camera permission for video recording
- Microphone permission for audio recording
- Photo library permission for saving to gallery

### iOS Setup
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to record videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save videos</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs photo library access to save videos</string>
```

## Troubleshooting

### Videos Missing After App Restart
1. Check console logs for database path and file existence
2. Verify app has proper permissions
3. Ensure videos are saved to documents directory
4. Check for orphaned database entries

### Permission Issues
1. Delete and reinstall app to reset permissions
2. Check iOS Settings > Privacy & Security > Camera/Microphone
3. Ensure device restrictions are not blocking permissions
