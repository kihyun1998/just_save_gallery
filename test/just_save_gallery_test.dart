import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_save_gallery/just_save_gallery.dart';
import 'package:just_save_gallery/src/platform/method_channel.dart';
import 'package:just_save_gallery/src/platform/platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A mock platform that records calls and can be configured to throw.
class MockJustSaveGalleryPlatform
    with MockPlatformInterfaceMixin
    implements JustSaveGalleryPlatform {
  Map<String, dynamic>? lastArgs;
  String? lastFilePath;
  Uint8List? lastBytes;
  PlatformException? exceptionToThrow;

  @override
  Future<String> saveBytes(Uint8List bytes, Map<String, dynamic> args) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    lastBytes = bytes;
    lastArgs = args;
    return 'content://media/external/images/media/123';
  }

  @override
  Future<String> saveFile(String filePath, Map<String, dynamic> args) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    lastFilePath = filePath;
    lastArgs = args;
    return 'content://media/external/videos/media/456';
  }
}

void main() {
  final JustSaveGalleryPlatform initialPlatform =
      JustSaveGalleryPlatform.instance;

  late MockJustSaveGalleryPlatform fakePlatform;
  late JustSaveGallery plugin;

  setUp(() {
    fakePlatform = MockJustSaveGalleryPlatform();
    JustSaveGalleryPlatform.instance = fakePlatform;
    plugin = JustSaveGallery();
  });

  test('MethodChannelJustSaveGallery is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelJustSaveGallery>());
  });

  // ---- saveImage ----

  group('saveImage', () {
    test('returns saved URI', () async {
      final result = await plugin.saveImage(
        Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        name: 'test.jpg',
      );
      expect(result, 'content://media/external/images/media/123');
    });

    test('passes correct args with defaults', () async {
      final bytes = Uint8List.fromList([0x89, 0x50]);
      await plugin.saveImage(bytes, name: 'photo.png');

      expect(fakePlatform.lastBytes, bytes);
      expect(fakePlatform.lastArgs!['name'], 'photo.png');
      expect(fakePlatform.lastArgs!['mediaType'], 'image');
      expect(fakePlatform.lastArgs!['requestPermission'], true);
      expect(fakePlatform.lastArgs!.containsKey('albumName'), false);
    });

    test('passes albumName and requestPermission when provided', () async {
      await plugin.saveImage(
        Uint8List.fromList([0x00]),
        name: 'img.jpg',
        albumName: 'Vacation',
        requestPermission: false,
      );

      expect(fakePlatform.lastArgs!['albumName'], 'Vacation');
      expect(fakePlatform.lastArgs!['requestPermission'], false);
    });
  });

  // ---- saveVideo ----

  group('saveVideo', () {
    test('returns saved URI', () async {
      final result = await plugin.saveVideo(
        Uint8List.fromList([0x00]),
        name: 'clip.mp4',
      );
      expect(result, 'content://media/external/images/media/123');
    });

    test('passes mediaType as video', () async {
      await plugin.saveVideo(
        Uint8List.fromList([0x00]),
        name: 'clip.mp4',
        albumName: 'Clips',
      );

      expect(fakePlatform.lastArgs!['mediaType'], 'video');
      expect(fakePlatform.lastArgs!['albumName'], 'Clips');
    });
  });

  // ---- saveFileToGallery ----

  group('saveFileToGallery', () {
    test('returns saved URI', () async {
      final result = await plugin.saveFileToGallery('/tmp/test.jpg');
      expect(result, 'content://media/external/videos/media/456');
    });

    test('passes file path to platform', () async {
      await plugin.saveFileToGallery('/tmp/photo.jpg');
      expect(fakePlatform.lastFilePath, '/tmp/photo.jpg');
    });

    test('infers image type from image extensions', () async {
      for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp']) {
        await plugin.saveFileToGallery('/tmp/file.$ext');
        expect(fakePlatform.lastArgs!['mediaType'], 'image',
            reason: '.$ext should be inferred as image');
      }
    });

    test('infers video type from video extensions', () async {
      for (final ext in ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp']) {
        await plugin.saveFileToGallery('/tmp/file.$ext');
        expect(fakePlatform.lastArgs!['mediaType'], 'video',
            reason: '.$ext should be inferred as video');
      }
    });

    test('extracts file name from path', () async {
      await plugin.saveFileToGallery('/some/deep/path/myfile.png');
      expect(fakePlatform.lastArgs!['name'], 'myfile.png');
    });

    test('passes albumName when provided', () async {
      await plugin.saveFileToGallery('/tmp/f.jpg', albumName: 'Album');
      expect(fakePlatform.lastArgs!['albumName'], 'Album');
    });
  });

  // ---- Error mapping ----

  group('error mapping', () {
    test('maps PERMISSION_DENIED to SaveErrorCode.permissionDenied', () async {
      fakePlatform.exceptionToThrow = PlatformException(
        code: 'PERMISSION_DENIED',
        message: 'denied',
      );

      expect(
        () => plugin.saveImage(Uint8List(0), name: 'a.jpg'),
        throwsA(isA<SaveException>().having(
          (e) => e.code,
          'code',
          SaveErrorCode.permissionDenied,
        )),
      );
    });

    test('maps DISK_FULL to SaveErrorCode.diskFull', () async {
      fakePlatform.exceptionToThrow = PlatformException(
        code: 'DISK_FULL',
        message: 'no space',
      );

      expect(
        () => plugin.saveImage(Uint8List(0), name: 'a.jpg'),
        throwsA(isA<SaveException>().having(
          (e) => e.code,
          'code',
          SaveErrorCode.diskFull,
        )),
      );
    });

    test('maps INVALID_FORMAT to SaveErrorCode.invalidFormat', () async {
      fakePlatform.exceptionToThrow = PlatformException(
        code: 'INVALID_FORMAT',
        message: 'bad data',
      );

      expect(
        () => plugin.saveImage(Uint8List(0), name: 'a.jpg'),
        throwsA(isA<SaveException>().having(
          (e) => e.code,
          'code',
          SaveErrorCode.invalidFormat,
        )),
      );
    });

    test('maps FILE_NOT_FOUND to SaveErrorCode.fileNotFound', () async {
      fakePlatform.exceptionToThrow = PlatformException(
        code: 'FILE_NOT_FOUND',
        message: 'not found',
      );

      expect(
        () => plugin.saveFileToGallery('/nonexistent.jpg'),
        throwsA(isA<SaveException>().having(
          (e) => e.code,
          'code',
          SaveErrorCode.fileNotFound,
        )),
      );
    });

    test('maps unknown codes to SaveErrorCode.unknown', () async {
      fakePlatform.exceptionToThrow = PlatformException(
        code: 'SOMETHING_ELSE',
        message: 'weird error',
      );

      expect(
        () => plugin.saveImage(Uint8List(0), name: 'a.jpg'),
        throwsA(isA<SaveException>().having(
          (e) => e.code,
          'code',
          SaveErrorCode.unknown,
        )),
      );
    });

    test('preserves error message', () async {
      fakePlatform.exceptionToThrow = PlatformException(
        code: 'PERMISSION_DENIED',
        message: 'Storage permission denied by user',
      );

      expect(
        () => plugin.saveImage(Uint8List(0), name: 'a.jpg'),
        throwsA(isA<SaveException>().having(
          (e) => e.message,
          'message',
          'Storage permission denied by user',
        )),
      );
    });

    test('error mapping works for saveFileToGallery too', () async {
      fakePlatform.exceptionToThrow = PlatformException(
        code: 'DISK_FULL',
        message: 'no space left',
      );

      expect(
        () => plugin.saveFileToGallery('/tmp/video.mp4'),
        throwsA(isA<SaveException>().having(
          (e) => e.code,
          'code',
          SaveErrorCode.diskFull,
        )),
      );
    });
  });
}
