import 'package:flutter_test/flutter_test.dart';
import 'package:photo_finder/services/share_filename.dart';

void main() {
  test('adds extension from mime when display name has none', () {
    final name = resolveShareFileName(
      displayName: 'Sunset at the beach',
      mimeType: 'image/jpeg',
    );
    expect(name, 'Sunset at the beach.jpg');
  });
}
