## 0.1.0

* Initial release.
* Save images and videos to the device gallery from raw bytes or file path.
* Support custom album/folder names.
* Automatic file name numbering to avoid duplicates.
* Built-in permission handling with opt-out option.
* Typed error handling via `SaveException` and `SaveErrorCode`.
* Android: MediaStore API with scoped storage support (API 29+).
* iOS: PHPhotoLibrary with add-only permission.
