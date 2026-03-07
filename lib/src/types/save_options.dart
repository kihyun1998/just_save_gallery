import 'media_type.dart';

/// Options for saving media to the gallery.
///
/// Example usage:
/// ```dart
/// final options = SaveOptions(
///   name: 'vacation.jpg',
///   albumName: 'My Trip',
/// );
/// ```
class SaveOptions {
  /// Creates [SaveOptions].
  ///
  /// [name] is the desired file name including extension (e.g. `'photo.jpg'`).
  /// The extension is used to infer the media type when [mediaType] is not
  /// explicitly provided.
  ///
  /// [albumName] is an optional album or folder name. When omitted, the file
  /// is saved to the device's default gallery location.
  ///
  /// When [requestPermission] is `true` (the default), the plugin will
  /// automatically request the required storage permission if it has not
  /// already been granted.
  const SaveOptions({
    required this.name,
    this.albumName,
    this.mediaType,
    this.requestPermission = true,
  });

  /// The desired file name including extension (e.g. `'photo.jpg'`).
  final String name;

  /// An optional album or folder name to save the file into.
  final String? albumName;

  /// The type of media being saved.
  ///
  /// If omitted, the plugin infers the type from the file extension in [name].
  final MediaType? mediaType;

  /// Whether to automatically request permission if not already granted.
  ///
  /// Defaults to `true`. Set to `false` if your app handles permission
  /// requests separately.
  final bool requestPermission;
}
