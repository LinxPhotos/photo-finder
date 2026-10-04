import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_finder/services/file_type_detector.dart';

void main() {
  test('detects JPEG magic bytes', () {
    final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);
    final detected = FileTypeDetector.detect(bytes);
    expect(detected?.extension, 'jpg');
    expect(detected?.kind, MediaKind.image);
  });

  test('maps image/jpeg mime to jpg', () {
    expect(FileTypeDetector.extensionForMime('image/jpeg'), 'jpg');
  });
}
