# just_save_gallery

A lightweight Flutter plugin that **just saves** images and videos to the device gallery. No read, no delete, no list — just save.

Supports both raw bytes and file path inputs on Android and iOS.

## Features

- Save images and videos from `Uint8List` bytes
- Save files directly from a file path (memory-efficient for large videos)
- Custom album/folder names
- Automatic file name numbering to avoid duplicates
- Built-in permission handling (with opt-out)
- Typed error handling via `SaveException`

## Installation

```yaml
dependencies:
  just_save_gallery: ^0.1.0
```

## Setup

### Android

No additional setup required. The plugin declares `WRITE_EXTERNAL_STORAGE` (maxSdkVersion 28) automatically.

### iOS

Add the following key to your `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app saves photos and videos to your photo library.</string>
```

## Usage

```dart
import 'package:just_save_gallery/just_save_gallery.dart';

final gallery = JustSaveGallery();
```

### Save image from bytes

```dart
final uri = await gallery.saveImage(
  imageBytes,
  name: 'photo.jpg',
  albumName: 'My Album',
);
```

### Save video from bytes

```dart
final uri = await gallery.saveVideo(
  videoBytes,
  name: 'clip.mp4',
  albumName: 'My Videos',
);
```

### Save file from path

```dart
final uri = await gallery.saveFileToGallery(
  '/path/to/video.mp4',
  albumName: 'Downloads',
);
```

The media type is inferred from the file extension automatically.

### Error handling

```dart
try {
  await gallery.saveImage(bytes, name: 'photo.jpg');
} on SaveException catch (e) {
  switch (e.code) {
    case SaveErrorCode.permissionDenied:
      // Handle permission denied
      break;
    case SaveErrorCode.diskFull:
      // Handle disk full
      break;
    case SaveErrorCode.invalidFormat:
      // Handle invalid format
      break;
    case SaveErrorCode.fileNotFound:
      // Handle file not found
      break;
    case SaveErrorCode.unknown:
      // Handle unknown error
      break;
  }
}
```

### Disable automatic permission request

```dart
await gallery.saveImage(
  bytes,
  name: 'photo.jpg',
  requestPermission: false, // Handle permission yourself
);
```

## Platform details

| | Android | iOS |
|---|---|---|
| API | MediaStore | PHPhotoLibrary |
| Permission | `WRITE_EXTERNAL_STORAGE` (API ≤ 28 only) | Add-only (`NSPhotoLibraryAddUsageDescription`) |
| Return value | `content://` URI | Local identifier |
| Scoped storage | API 29+ with `IS_PENDING` | N/A |

## License

MIT
