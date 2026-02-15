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

### Permissions Required
- Camera permission for video recording
- Microphone permission for audio recording
- Photo library permission for saving to gallery
