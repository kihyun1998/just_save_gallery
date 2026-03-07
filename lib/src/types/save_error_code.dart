/// Error codes returned when a save operation fails.
enum SaveErrorCode {
  /// The user denied the required permission.
  permissionDenied,

  /// Not enough disk space to save the file.
  diskFull,

  /// The file format is not supported or the data is corrupted.
  invalidFormat,

  /// The source file path does not exist or is not readable.
  fileNotFound,

  /// An unknown or platform-specific error occurred.
  unknown,
}
