import 'save_error_code.dart';

/// Represents a failed save operation.
///
/// Thrown by [JustSaveGallery] methods when the media could not be saved.
/// Inspect [code] to determine the failure reason programmatically, and
/// [message] for a human-readable description.
class SaveException implements Exception {
  /// Creates a [SaveException] with the given [code] and optional [message].
  const SaveException({required this.code, this.message});

  /// The error code describing the failure reason.
  final SaveErrorCode code;

  /// An optional human-readable description of the error.
  final String? message;

  @override
  String toString() =>
      'SaveException($code${message != null ? ': $message' : ''})';
}
