# Coomer Downloader

A modern Flutter application for downloading content from Coomer.st. Supports OnlyFans and Fansly platforms.

## Features

- **Creator Search**: Search creators by username across multiple platforms
- **Bulk Download**: Download all content from a creator with one tap
- **Download Manager**: Queue-based download system with pause/resume support
- **Favorites**: Save favorite creators for quick access
- **Dark/Light Theme**: Automatic theme switching with manual override
- **Offline Storage**: Downloaded content organized by creator folders
- **Download History**: Track completed downloads and avoid duplicates

## Screenshots

| Home | Creator Detail | Downloads |
|------|----------------|-----------|
| Search creators | Browse posts | Manage downloads |

## Requirements

- Android 5.0 (API 21) or higher
- Storage permission for saving files
- Internet connection

## Installation

### From Release
1. Download the latest APK from [Releases](../../releases)
2. Enable "Install from unknown sources" on your device
3. Install the APK

### Build from Source

```bash
# Clone the repository
git clone https://github.com/kynarix/CoomerDownloader.git
cd CoomerDownloader

# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── creator.dart
│   ├── download_item.dart
│   └── post.dart
├── providers/                # State management
│   ├── app_provider.dart
│   └── download_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── creator_detail_screen.dart
│   ├── downloads_screen.dart
│   └── ...
├── services/                 # Business logic
│   ├── api_service.dart
│   ├── download_service.dart
│   └── storage_service.dart
├── utils/                    # Utilities
│   ├── constants.dart
│   └── theme.dart
└── widgets/                  # Reusable components
    ├── creator_card.dart
    ├── post_card.dart
    └── ...
```

## Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: Provider
- **HTTP Client**: Dio
- **Image Caching**: cached_network_image
- **Local Storage**: SharedPreferences, path_provider
- **UI**: Material Design 3, Google Fonts

## Configuration

Default download location: `Android/data/com.example.coomer_downloader/files/Downloads`

Files are organized by creator name in separate folders.

## API

This app uses the Coomer.st public API:
- Base URL: `https://coomer.st/api/v1`
- Endpoints:
  - `/{service}/user/{id}/profile` - Creator profile
  - `/{service}/user/{id}/posts` - Creator posts

## License

This project is open source and available under the MIT License.

## Disclaimer

This application is for educational purposes only. Users are responsible for ensuring their use complies with applicable laws and platform terms of service.
